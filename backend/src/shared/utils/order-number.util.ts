/**
 * Generate a unique order number
 * Format: DZ-YYYYMMDD-XXX
 * @returns Order number string
 */
export function generateOrderNumber(): string {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
  
  return `DZ-${year}${month}${day}-${random}`;
}

/**
 * Generate a 4-digit confirmation code
 * @returns 4-digit string
 */
export function generateConfirmationCode(): string {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

/**
 * Generate invoice number
 * Format: FACT-YYYY-XXXX
 * @returns Invoice number string
 */
export function generateInvoiceNumber(): string {
  const year = new Date().getFullYear();
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `FACT-${year}-${random}`;
}

/**
 * Parse order number to extract date
 * @param orderNumber Order number string
 * @returns Date object or null if invalid
 */
export function parseOrderDate(orderNumber: string): Date | null {
  const match = orderNumber.match(/DZ-(\d{4})(\d{2})(\d{2})-\d{3}/);
  if (!match) return null;
  
  const [, year, month, day] = match;
  return new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
}
