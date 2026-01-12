import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';

@ValidatorConstraint({ async: false })
export class IsAlgerianPhoneConstraint implements ValidatorConstraintInterface {
  validate(phone: string): boolean {
    if (!phone) return false;
    
    // Algerian phone format: +213XXXXXXXXX or 0XXXXXXXXX
    const algerianPhoneRegex = /^(\+213|0)(5|6|7)[0-9]{8}$/;
    return algerianPhoneRegex.test(phone.replace(/\s/g, ''));
  }

  defaultMessage(): string {
    return 'Phone number must be a valid Algerian phone number (+213XXXXXXXXX or 0XXXXXXXXX)';
  }
}

export function IsAlgerianPhone(validationOptions?: ValidationOptions) {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      constraints: [],
      validator: IsAlgerianPhoneConstraint,
    });
  };
}
