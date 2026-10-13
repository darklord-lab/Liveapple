import { Router } from 'express';
import { StoreController } from '../controllers/store.controller.js';
import { authenticate, requireRole } from '../middlewares/auth.js';
import { tenantGuard } from '../middlewares/tenant.js';

const router = Router();

// Webhook endpoint (verified via HMAC signature)
router.post('/webhooks/razorpay', StoreController.handleWebhook);

// Protected routes (require authentication and tenant guard)
router.use(authenticate, tenantGuard);

// Offerings
router.get('/offerings', StoreController.listOfferings);
router.get('/offerings/:id', StoreController.getOffering);
router.post('/offerings', requireRole(['ADMIN']), StoreController.createOffering);
router.patch('/offerings/:id', requireRole(['ADMIN']), StoreController.updateOffering);
router.delete('/offerings/:id', requireRole(['ADMIN']), StoreController.deleteOffering);

// Coupons
router.get('/coupons', requireRole(['ADMIN']), StoreController.listCoupons);
router.post('/coupons', requireRole(['ADMIN']), StoreController.createCoupon);
router.post('/coupons/validate', StoreController.validateCoupon);

// Checkout & Payment Verification
router.post('/checkout', requireRole(['STUDENT', 'ADMIN']), StoreController.checkout);
router.post('/verify-payment', requireRole(['STUDENT', 'ADMIN']), StoreController.verifyPayment);

// Purchases, Invoices & Refunds
router.get('/purchases', StoreController.listPurchases);
router.get('/purchases/:id/invoice', StoreController.getInvoice);
router.post('/purchases/:id/refund', requireRole(['ADMIN']), StoreController.refundPurchase);

export default router;
