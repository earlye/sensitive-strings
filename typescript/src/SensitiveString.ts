// Forked from https://www.npmjs.com/package/@earnest-labs/ts-sensitivestring
// License: MIT
import { sha256 as nobleSha256 } from './noble-hashes/sha2.ts';
import { bytesToHex,utf8ToBytes } from './noble-hashes/utils.ts';
import { INSPECT_CUSTOM, type InspectOptions, type Inspect } from './nodejs/util-inspect.ts';

const VALUE_SYMBOL = Symbol('SensitiveStringValue');

/**
 * sha256 - provide a sha256 value of the provided content string
 * 
 * @param content, a string encoded as utf-8
 * @returns a sha256 digest.
 */
export function sha256(content:string): string {
  return bytesToHex(nobleSha256.create().update(utf8ToBytes(content)).digest());
}

/**
 * JSONReplacer is the type of the function that you can pass to JSON.stringify
 * in order to replace values during JSON serialization.
 * 
 * You might be tempted to extract using the below,
 * but this is not correct because that yields (string | number)[] | null | undefined
 *   type JSONReplacer = Parameters<typeof JSON.stringify>[1] // incorrect :-(
 * It'd be nice if tsc's library included a proper type for this rather than just
 * inlining it in the decl of one override of JSON.stringify
 */
export type JSONReplacer = (key: string, value: any) => any;

/**
 * SensitiveString is a type that helps avoid accidental persistence of secrets.
 * It wraps a string value and provides a sha256 hash of the value instead of the
 * raw value. This is useful because it allows you to see that there is a SensitiveString
 * instance, and if necessary, write a known value locally in order to compare the sha
 * against what you're seeing in logs. The reason for this is that sometimes it's useful
 * to be able to see the hashed value for debugging purposes.
 * 
 * SensitiveString instances are immutable, so they can be safely shared across threads and
 * processes.
 */
export class SensitiveString {
  [VALUE_SYMBOL]: string;

  constructor(value:string) {
    this[VALUE_SYMBOL] = value;
  }

  toString(): string {
    return "sha256:" + sha256(this[VALUE_SYMBOL]);
  }

  toLocaleString(): string {
    return this.toString();
  }

  toJSON(): string {
    return this.toString();
  }

  [INSPECT_CUSTOM](depth: number, options: InspectOptions, inspect: Inspect): string {
    return this.toString();
  }

  getValue(): string {
    return this[VALUE_SYMBOL];
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
   * it is a string or SensitiveString and throws an error otherwise.
   */
  static ExtractRequiredValue(input: string | SensitiveString | null | undefined): string {
    if (SensitiveString.IsSensitiveString(input))
      return (input as SensitiveString)!.getValue();
    if (input)
      return input as string;
    throw new Error("Required input to be a string or SensitiveString, got undefined or null.");
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

  /**
   * PlaintextReplacer is a JSONReplacer function that will
   * extract the plaintext value of any SensitiveString objects
   * during json serialization so that you can serialize secrets if
   * you explicitly want to.
   */ 
  static PlaintextReplacer(replacerFunction : JSONReplacer | undefined = undefined) : JSONReplacer {
    const otherReplacerFunction = replacerFunction === undefined ?
      (key : string , value: any ): any => value :
      replacerFunction;
    return (key:any, value:any) : any => {
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
