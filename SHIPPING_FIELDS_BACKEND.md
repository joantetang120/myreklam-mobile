# New Shipping Fields for Backend Integration

## Overview
When the availability location is set to **"En ligne"** (online), two new shipping-related fields are now available in the bon plan creation/edit form.

## Field Names and Details

### 1. `shipping_option` (String)
- **Type**: String (radio selection)
- **Possible Values**: 
  - `"free"` - Livraison gratuite (Free shipping)
  - `"paid"` - Frais de port (Shipping costs apply)
- **Default**: `"free"`
- **Required**: Only when `available_location_type` is `"En ligne"`
- **Description**: Indicates whether the online offer includes free shipping or has shipping costs

### 2. `shipping_cost` (Decimal/Number)
- **Type**: Decimal/Float (currency amount in euros)
- **Possible Values**: Any positive number (e.g., `5.99`, `10.00`)
- **Default**: `null` or empty
- **Required**: Only when `shipping_option` is `"paid"`
- **Description**: The amount of shipping costs in euros (€)
- **Validation**: 
  - Should be a positive number
  - Should only be saved/validated when `shipping_option` is `"paid"`
  - Should be cleared/ignored when `shipping_option` is `"free"`

## Usage Logic

1. These fields are **only relevant** when `available_location_type` = `"En ligne"`
2. When `available_location_type` = `"En magasin"`, these fields should be ignored/null
3. The two shipping options are **mutually exclusive** (radio buttons):
   - Selecting "Livraison gratuite" sets `shipping_option = "free"` and clears `shipping_cost`
   - Selecting "Frais de port" sets `shipping_option = "paid"` and enables the cost input field

## Example Payloads

### Free Shipping Example
```json
{
  "available_location_type": "En ligne",
  "shipping_option": "free",
  "shipping_cost": null
}
```

### Paid Shipping Example
```json
{
  "available_location_type": "En ligne",
  "shipping_option": "paid",
  "shipping_cost": 7.50
}
```

### In-Store Example (shipping fields not applicable)
```json
{
  "available_location_type": "En magasin",
  "shipping_option": null,
  "shipping_cost": null
}
```

## Database Schema Suggestions

```sql
-- Add these columns to your bon_plans table
ALTER TABLE bon_plans 
ADD COLUMN shipping_option VARCHAR(10) DEFAULT 'free',
ADD COLUMN shipping_cost DECIMAL(10, 2) DEFAULT NULL;

-- Optional: Add constraint to ensure shipping_cost is only set when shipping_option is 'paid'
ALTER TABLE bon_plans
ADD CONSTRAINT check_shipping_cost 
CHECK (
  (shipping_option = 'free' AND shipping_cost IS NULL) OR 
  (shipping_option = 'paid' AND shipping_cost IS NOT NULL) OR
  (shipping_option IS NULL)
);
```

## Frontend Implementation Location
- File: `lib/screens/creer_bon_plan_screen.dart`
- State variables: `_shippingOption` (String), `_shippingCostController` (TextEditingController)
- Lines: 75-76, 164-166, 2231-2297
