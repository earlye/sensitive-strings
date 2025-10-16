// Forked from https://www.npmjs.com/package/@earnest-labs/ts-sensitivestring
// License: MIT
import crypto from 'crypto';
import util from 'node:util';
import assert from 'node:assert';

function sha256(content:string): string {
  return crypto.createHash('sha256').update(content, "utf8").digest('hex');
}

type JSONReplacer = (key: string, value: any) => any;

export class SensitiveString {
  #value: string;
  constructor(value:string) {
    this.#value = value;
  }
  toString(): string {
    return "sha256:" + sha256(this.#value);
  }
  toLocaleString(): string {
    return this.toString();
  }
  toJSON(): string {
    return this.toString();
  }
  [util.inspect.custom](depth: number, options: util.InspectOptions, inspect: typeof util.inspect): string {
    return this.toString();
  }
  getValue(): string {
    return this.#value;
  }
  get length(): number {
    return this.#value.length;
  }
  /**
   * IsSensitiveString returns true if and only if `input` is a
   * SensitiveString (from any version of the SensitiveString library, not just this one)
   */
  static IsSensitiveString(input: any): boolean {
    if (input == undefined || input == null) {
      return false;
    }
    if (input instanceof SensitiveString) {
      return true;
    }
    if (input?.constructor?.name == 'SensitiveString') {
      return true;
    }
    return false;
  }

  /**
   * ExtractValue obtains the plaintext value of `input` if it is a
   * string or SensitiveString, and undefined otherwise.
   */
  static ExtractValue(input: string | SensitiveString | null | undefined): string | null | undefined {
    if (SensitiveString.IsSensitiveString(input))
      return (input as SensitiveString)!.getValue();

    return input as string | null | undefined;
  }

  /**
   * ExtractRequiredValue obtains the plaintext value of `input` if
   * it is a string or SensitiveString and throws an assertion
   * failure otherwise.
   */
  static ExtractRequiredValue(input: string | SensitiveString | null | undefined): string {
    if (SensitiveString.IsSensitiveString(input))
      return (input as SensitiveString)!.getValue();
    if (input)
      return input as string;
    assert.fail("Required input to be a string or SensitiveString, got undefined or null.");
  }

  /**
   * Convert input into a SensitiveString, unless it is null/undefined.
   */
  static Sensitive(input: any): SensitiveString | null | undefined {
    if (SensitiveString.IsSensitiveString(input))
      return input;
    if (input === undefined)
      return undefined;
    if (input === null)
      return null;
    return new SensitiveString(input);
  }


  /// UnsecuredJSONReplacer is a JSONReplacer function that will
  /// extract the plaintext value of any SensitiveString objects
  /// during json serialization so that you can serialize secrets if
  /// you explicitly want to.
  static UnsecuredJSONReplacer(replacerFunction : JSONReplacer | undefined = undefined) : JSONReplacer {
    const otherReplacerFunction = replacerFunction === undefined ?
      (key : string , value: any ): any => value :
      replacerFunction;
    return (key, value) => {
      if (value instanceof Object) {
        let result: Record<string, any> = {};
        for (const child of Object.keys(value)) {
          if (SensitiveString.IsSensitiveString(value[child])) {
            result[child] = value[child].getValue();
          }
          else {
            result[child] = value[child];
          }
        }
        return otherReplacerFunction(key, result);
      }
      return otherReplacerFunction(key, value);
    };
  }
}
export default SensitiveString;
