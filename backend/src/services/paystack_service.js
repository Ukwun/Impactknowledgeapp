/**
 * Paystack Payment Service
 * Handles card payments and bank transfers
 */

const https = require('https');
const crypto = require('crypto');

class PaystackService {
  constructor() {
    this.baseUrl = 'https://api.paystack.co';
    this.publicKey = process.env.PAYSTACK_PUBLIC_KEY;
    this.secretKey = process.env.PAYSTACK_SECRET_KEY;
  }

  /**
   * Make request to Paystack API
   */
  private async makeRequest(method, endpoint, data = null) {
    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'api.paystack.co',
        port: 443,
        path: endpoint,
        method: method,
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
          'Content-Type': 'application/json',
        },
      };

      const req = https.request(options, (res) => {
        let body = '';

        res.on('data', (chunk) => {
          body += chunk;
        });

        res.on('end', () => {
          try {
            const response = JSON.parse(body);
            if (res.statusCode >= 200 && res.statusCode < 300) {
              resolve(response.data);
            } else {
              reject(new Error(response.message || 'Paystack API error'));
            }
          } catch (e) {
            reject(e);
          }
        });
      });

      req.on('error', reject);

      if (data) {
        req.write(JSON.stringify(data));
      }

      req.end();
    });
  }

  /**
   * Initialize card payment (returns paymentUrl)
   */
  async initializeCardPayment(email, amount, reference, metadata = {}) {
    try {
      const data = {
        email,
        amount: Math.round(amount * 100), // Convert to kobo
        reference,
        metadata,
        channels: ['card', 'mobile_money', 'ussd'],
      };

      const result = await this.makeRequest('POST', '/transaction/initialize', data);
      
      return {
        success: true,
        reference: result.reference,
        paymentUrl: result.authorization_url,
        accessCode: result.access_code,
      };
    } catch (error) {
      console.error('Initialize card payment error:', error);
      throw error;
    }
  }

  /**
   * Initialize bank transfer payment
   * Returns bank details + reference for user transfer
   */
  async initializeBankTransfer(email, amount, reference, metadata = {}) {
    try {
      // Generate unique transfer reference for tracking
      const transferReference = `${process.env.BUSINESS_ACCOUNT_REFERENCE_PREFIX}_${reference}`;
      
      const bankDetails = {
        accountName: process.env.BUSINESS_BANK_ACCOUNT_NAME,
        accountNumber: process.env.BUSINESS_BANK_ACCOUNT_NUMBER,
        bankCode: process.env.BUSINESS_BANK_CODE,
        bankName: process.env.BUSINESS_BANK_NAME,
        amount: amount, // In NGN/currency
        transferReference: transferReference,
        description: metadata.description || 'Payment for ImpactKnowledge',
      };

      return {
        success: true,
        method: 'bank_transfer',
        transferReference,
        bankDetails,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      };
    } catch (error) {
      console.error('Initialize bank transfer error:', error);
      throw error;
    }
  }

  /**
   * Verify card payment (check if successful)
   */
  async verifyCardPayment(reference) {
    try {
      const result = await this.makeRequest('GET', `/transaction/verify/${reference}`);

      return {
        success: result.status === 'success',
        reference: result.reference,
        amount: result.amount / 100, // Convert from kobo
        email: result.customer.email,
        paymentMethod: result.channel,
        paidAt: result.paid_at,
        authorization: result.authorization,
        metadata: result.metadata,
      };
    } catch (error) {
      console.error('Verify card payment error:', error);
      throw error;
    }
  }

  /**
   * Verify bank transfer (via webhook or manual check)
   * In production, bank would notify via Paystack webhook
   */
  async verifyBankTransfer(transferReference) {
    try {
      // In real implementation, check against bank reconciliation
      // For now, returns status model
      return {
        success: false, // Requires manual verification or webhook
        reference: transferReference,
        status: 'pending', // pending, completed, failed
        message: 'Bank transfer verification requires manual confirmation',
      };
    } catch (error) {
      console.error('Verify bank transfer error:', error);
      throw error;
    }
  }

  /**
   * Get all banks for transfer recipient
   */
  async getBanks() {
    try {
      const result = await this.makeRequest('GET', '/bank?currency=NGN');
      return result || [];
    } catch (error) {
      console.error('Get banks error:', error);
      return [];
    }
  }

  /**
   * Verify bank account (for wallet top-up)
   */
  async verifyBankAccount(accountNumber, bankCode) {
    try {
      const result = await this.makeRequest(
        'GET',
        `/bank/resolve?account_number=${accountNumber}&bank_code=${bankCode}`
      );

      return {
        success: true,
        accountName: result.account_name,
        accountNumber: accountNumber,
        bankCode: bankCode,
      };
    } catch (error) {
      console.error('Verify bank account error:', error);
      return {
        success: false,
        error: 'Account verification failed',
      };
    }
  }

  /**
   * Verify webhook signature
   */
  verifyWebhookSignature(signature, body) {
    const hash = crypto
      .createHmac('sha512', this.secretKey)
      .update(body)
      .digest('hex');

    return hash === signature;
  }

  /**
   * Create transfer recipient (for payouts)
   */
  async createTransferRecipient(accountNumber, bankCode, recipientName) {
    try {
      const data = {
        type: 'nuban',
        name: recipientName,
        account_number: accountNumber,
        bank_code: bankCode,
        currency: 'NGN',
      };

      const result = await this.makeRequest(
        'POST',
        '/transferrecipient',
        data
      );

      return {
        success: true,
        recipientCode: result.recipient_code,
        name: result.name,
        accountNumber: result.details.account_number,
        bankCode: result.details.bank_code,
      };
    } catch (error) {
      console.error('Create transfer recipient error:', error);
      throw error;
    }
  }

  /**
   * Initiate transfer (for payouts)
   */
  async initiateTransfer(recipientCode, amount, reference, description = '') {
    try {
      const data = {
        source: 'balance',
        amount: Math.round(amount * 100), // Convert to kobo
        recipient: recipientCode,
        reference,
        reason: description,
      };

      const result = await this.makeRequest('POST', '/transfer', data);

      return {
        success: true,
        transferCode: result.transfer_code,
        reference: result.reference,
        amount: result.amount / 100,
        status: result.status,
        initiatedAt: result.createdAt,
      };
    } catch (error) {
      console.error('Initiate transfer error:', error);
      throw error;
    }
  }

  /**
   * Get transfer status
   */
  async getTransferStatus(transferCode) {
    try {
      const result = await this.makeRequest(
        'GET',
        `/transfer/${transferCode}`
      );

      return {
        success: true,
        transferCode: result.transfer_code,
        reference: result.reference,
        amount: result.amount / 100,
        status: result.status,
        reason: result.reason,
      };
    } catch (error) {
      console.error('Get transfer status error:', error);
      throw error;
    }
  }
}

module.exports = PaystackService;
