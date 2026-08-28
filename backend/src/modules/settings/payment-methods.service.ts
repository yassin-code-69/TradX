import { query } from '../../db/client.ts';
import { ConflictError, NotFoundError } from '../../utils/errors.ts';
import { formatMoney, toMinorUnits } from '../../utils/money.ts';
import type {
  CreatePaymentMethodInput,
  PaymentMethodItem,
  UpdatePaymentMethodInput,
} from './payment-methods.types.ts';

export class PaymentMethodsService {
  /**
   * List active payment methods for mobile users / deposit & withdrawal flow.
   */
  async getActivePaymentMethods(filter?: {
    type?: 'deposit' | 'withdraw' | 'all';
  }): Promise<PaymentMethodItem[]> {
    const conditions: string[] = ["status = 'ACTIVE'"];
    if (filter?.type === 'deposit') {
      conditions.push('deposit_enabled = true');
    } else if (filter?.type === 'withdraw') {
      conditions.push('withdraw_enabled = true');
    }

    const whereClause = `WHERE ${conditions.join(' AND ')}`;
    const res = await query(
      `SELECT * FROM payment_methods ${whereClause} ORDER BY display_order ASC, name ASC`
    );

    return res.rows.map(this.mapPaymentMethodRow);
  }

  /**
   * Admin list of all payment methods with pagination and status filters.
   */
  async getAllPaymentMethodsAdmin(filter?: {
    status?: string;
    type?: string;
    page?: number;
    limit?: number;
  }): Promise<{ methods: PaymentMethodItem[]; total: number; page: number; limit: number }> {
    const page = Math.max(1, filter?.page || 1);
    const limit = Math.min(100, Math.max(1, filter?.limit || 50));
    const offset = (page - 1) * limit;

    const conditions: string[] = [];
    const params: any[] = [];

    if (filter?.status) {
      params.push(filter.status);
      conditions.push(`status = $${params.length}`);
    }

    if (filter?.type === 'deposit') {
      conditions.push('deposit_enabled = true');
    } else if (filter?.type === 'withdraw') {
      conditions.push('withdraw_enabled = true');
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const countRes = await query(
      `SELECT count(*) as total FROM payment_methods ${whereClause}`,
      params
    );
    const total = parseInt(countRes.rows[0]?.total || '0', 10);

    const listParams = [...params, limit, offset];
    const listRes = await query(
      `SELECT * FROM payment_methods
       ${whereClause}
       ORDER BY display_order ASC, created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const methods = listRes.rows.map(this.mapPaymentMethodRow);
    return { methods, total, page, limit };
  }

  /**
   * Get payment method by ID or Code.
   */
  async getPaymentMethodById(idOrCode: string | number): Promise<PaymentMethodItem> {
    const isNumeric = typeof idOrCode === 'number' || /^\d+$/.test(String(idOrCode));
    const sql = isNumeric
      ? `SELECT * FROM payment_methods WHERE id = $1`
      : `SELECT * FROM payment_methods WHERE upper(code) = upper($1)`;

    const res = await query(sql, [idOrCode]);
    if (res.rows.length === 0) {
      throw new NotFoundError(`Payment method '${idOrCode}' not found`);
    }

    return this.mapPaymentMethodRow(res.rows[0]);
  }

  /**
   * Create new payment method (Admin).
   */
  async createPaymentMethod(
    adminUserId: string,
    input: CreatePaymentMethodInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ): Promise<PaymentMethodItem> {
    const code = input.code.trim().toUpperCase();

    // Check code uniqueness
    const existing = await query(`SELECT id FROM payment_methods WHERE upper(code) = $1`, [code]);
    if (existing.rows.length > 0) {
      throw new ConflictError(
        'DUPLICATE_REQUEST',
        `Payment method code '${code}' is already registered`
      );
    }

    const minDeposit = toMinorUnits(input.minimumDepositMinor ?? 10000);
    const maxDeposit = toMinorUnits(input.maximumDepositMinor ?? 2500000);
    const minWithdraw = toMinorUnits(input.minimumWithdrawMinor ?? 20000);
    const maxWithdraw = toMinorUnits(input.maximumWithdrawMinor ?? 2500000);
    const depFixedFee = toMinorUnits(input.depositFeeFixedMinor ?? 0);
    const withFixedFee = toMinorUnits(input.withdrawFeeFixedMinor ?? 0);

    const insertRes = await query(
      `INSERT INTO payment_methods (
         code, name, type, account_number, account_name, instructions,
         minimum_deposit_minor, maximum_deposit_minor, minimum_withdraw_minor, maximum_withdraw_minor,
         deposit_fee_percentage_basis_points, deposit_fee_fixed_minor,
         withdraw_fee_percentage_basis_points, withdraw_fee_fixed_minor,
         deposit_enabled, withdraw_enabled, status, display_order
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
       RETURNING *`,
      [
        code,
        input.name.trim(),
        input.type || 'MOBILE_BANKING',
        input.accountNumber.trim(),
        input.accountName.trim(),
        input.instructions.trim(),
        minDeposit.toString(),
        maxDeposit.toString(),
        minWithdraw.toString(),
        maxWithdraw.toString(),
        input.depositFeePercentageBasisPoints || 0,
        depFixedFee.toString(),
        input.withdrawFeePercentageBasisPoints || 0,
        withFixedFee.toString(),
        input.depositEnabled !== false,
        input.withdrawEnabled !== false,
        input.status || 'ACTIVE',
        input.displayOrder || 0,
      ]
    );

    const row = insertRes.rows[0];

    // Audit Log
    await query(
      `INSERT INTO audit_logs (
         actor_user_id, action, entity_type, entity_id, new_values, ip_address, user_agent, request_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'PAYMENT_METHOD_CREATE',
        'payment_methods',
        row.id.toString(),
        JSON.stringify(input),
        reqMeta?.ip || null,
        reqMeta?.userAgent || null,
        reqMeta?.requestId || null,
      ]
    );

    return this.mapPaymentMethodRow(row);
  }

  /**
   * Update payment method (Admin).
   */
  async updatePaymentMethod(
    adminUserId: string,
    id: string | number,
    input: UpdatePaymentMethodInput,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ): Promise<PaymentMethodItem> {
    const existingRes = await query(`SELECT * FROM payment_methods WHERE id = $1`, [id]);
    if (existingRes.rows.length === 0) {
      throw new NotFoundError(`Payment method with ID ${id} not found`);
    }

    const existing = existingRes.rows[0];

    const fields: string[] = [];
    const params: any[] = [];

    if (input.name !== undefined) {
      params.push(input.name.trim());
      fields.push(`name = $${params.length}`);
    }
    if (input.type !== undefined) {
      params.push(input.type);
      fields.push(`type = $${params.length}`);
    }
    if (input.accountNumber !== undefined) {
      params.push(input.accountNumber.trim());
      fields.push(`account_number = $${params.length}`);
    }
    if (input.accountName !== undefined) {
      params.push(input.accountName.trim());
      fields.push(`account_name = $${params.length}`);
    }
    if (input.instructions !== undefined) {
      params.push(input.instructions.trim());
      fields.push(`instructions = $${params.length}`);
    }
    if (input.minimumDepositMinor !== undefined) {
      params.push(toMinorUnits(input.minimumDepositMinor).toString());
      fields.push(`minimum_deposit_minor = $${params.length}`);
    }
    if (input.maximumDepositMinor !== undefined) {
      params.push(toMinorUnits(input.maximumDepositMinor).toString());
      fields.push(`maximum_deposit_minor = $${params.length}`);
    }
    if (input.minimumWithdrawMinor !== undefined) {
      params.push(toMinorUnits(input.minimumWithdrawMinor).toString());
      fields.push(`minimum_withdraw_minor = $${params.length}`);
    }
    if (input.maximumWithdrawMinor !== undefined) {
      params.push(toMinorUnits(input.maximumWithdrawMinor).toString());
      fields.push(`maximum_withdraw_minor = $${params.length}`);
    }
    if (input.depositFeePercentageBasisPoints !== undefined) {
      params.push(input.depositFeePercentageBasisPoints);
      fields.push(`deposit_fee_percentage_basis_points = $${params.length}`);
    }
    if (input.depositFeeFixedMinor !== undefined) {
      params.push(toMinorUnits(input.depositFeeFixedMinor).toString());
      fields.push(`deposit_fee_fixed_minor = $${params.length}`);
    }
    if (input.withdrawFeePercentageBasisPoints !== undefined) {
      params.push(input.withdrawFeePercentageBasisPoints);
      fields.push(`withdraw_fee_percentage_basis_points = $${params.length}`);
    }
    if (input.withdrawFeeFixedMinor !== undefined) {
      params.push(toMinorUnits(input.withdrawFeeFixedMinor).toString());
      fields.push(`withdraw_fee_fixed_minor = $${params.length}`);
    }
    if (input.depositEnabled !== undefined) {
      params.push(input.depositEnabled);
      fields.push(`deposit_enabled = $${params.length}`);
    }
    if (input.withdrawEnabled !== undefined) {
      params.push(input.withdrawEnabled);
      fields.push(`withdraw_enabled = $${params.length}`);
    }
    if (input.status !== undefined) {
      params.push(input.status);
      fields.push(`status = $${params.length}`);
    }
    if (input.displayOrder !== undefined) {
      params.push(input.displayOrder);
      fields.push(`display_order = $${params.length}`);
    }

    if (fields.length === 0) {
      return this.mapPaymentMethodRow(existing);
    }

    fields.push(`updated_at = now()`);
    params.push(id);

    const updateSql = `UPDATE payment_methods SET ${fields.join(', ')} WHERE id = $${params.length} RETURNING *`;
    const updateRes = await query(updateSql, params);

    // Audit Log
    await query(
      `INSERT INTO audit_logs (
         actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'PAYMENT_METHOD_UPDATE',
        'payment_methods',
        id.toString(),
        JSON.stringify(existing),
        JSON.stringify(updateRes.rows[0]),
        reqMeta?.ip || null,
        reqMeta?.userAgent || null,
        reqMeta?.requestId || null,
      ]
    );

    return this.mapPaymentMethodRow(updateRes.rows[0]);
  }

  /**
   * Delete / Deactivate payment method (Admin).
   */
  async deletePaymentMethod(
    adminUserId: string,
    id: string | number,
    reqMeta?: { ip?: string; userAgent?: string; requestId?: string }
  ): Promise<{ success: boolean; id: string }> {
    const existingRes = await query(`SELECT * FROM payment_methods WHERE id = $1`, [id]);
    if (existingRes.rows.length === 0) {
      throw new NotFoundError(`Payment method with ID ${id} not found`);
    }

    // Set to INACTIVE and disable deposit/withdraw
    await query(
      `UPDATE payment_methods
       SET status = 'INACTIVE', deposit_enabled = false, withdraw_enabled = false, updated_at = now()
       WHERE id = $1`,
      [id]
    );

    // Audit Log
    await query(
      `INSERT INTO audit_logs (
         actor_user_id, action, entity_type, entity_id, old_values, new_values, ip_address, user_agent, request_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        adminUserId,
        'PAYMENT_METHOD_DELETE',
        'payment_methods',
        id.toString(),
        JSON.stringify(existingRes.rows[0]),
        JSON.stringify({ status: 'INACTIVE', deposit_enabled: false, withdraw_enabled: false }),
        reqMeta?.ip || null,
        reqMeta?.userAgent || null,
        reqMeta?.requestId || null,
      ]
    );

    return { success: true, id: id.toString() };
  }

  private mapPaymentMethodRow(row: any): PaymentMethodItem {
    const minDep = BigInt(row.minimum_deposit_minor || 0);
    const maxDep = BigInt(row.maximum_deposit_minor || 0);
    const minWith = BigInt(row.minimum_withdraw_minor || 0);
    const maxWith = BigInt(row.maximum_withdraw_minor || 0);

    return {
      id: row.id.toString(),
      code: row.code,
      name: row.name,
      type: row.type,
      accountNumber: row.account_number,
      accountName: row.account_name,
      instructions: row.instructions,
      minimumDepositMinor: minDep.toString(),
      maximumDepositMinor: maxDep.toString(),
      minimumWithdrawMinor: minWith.toString(),
      maximumWithdrawMinor: maxWith.toString(),
      formattedMinDeposit: formatMoney(minDep, 'BDT'),
      formattedMaxDeposit: formatMoney(maxDep, 'BDT'),
      formattedMinWithdraw: formatMoney(minWith, 'BDT'),
      formattedMaxWithdraw: formatMoney(maxWith, 'BDT'),
      depositFeePercentageBasisPoints: Number(row.deposit_fee_percentage_basis_points || 0),
      depositFeeFixedMinor: row.deposit_fee_fixed_minor?.toString() || '0',
      withdrawFeePercentageBasisPoints: Number(row.withdraw_fee_percentage_basis_points || 0),
      withdrawFeeFixedMinor: row.withdraw_fee_fixed_minor?.toString() || '0',
      depositEnabled: Boolean(row.deposit_enabled),
      withdrawEnabled: Boolean(row.withdraw_enabled),
      status: row.status,
      displayOrder: Number(row.display_order || 0),
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}

export const paymentMethodsService = new PaymentMethodsService();
