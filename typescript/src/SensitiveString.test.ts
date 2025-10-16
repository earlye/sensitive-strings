// Forked from https://www.npmjs.com/package/@earnest-labs/ts-sensitivestring
// License: MIT
import SensitiveString from "./SensitiveString.ts";
import { test } from "node:test";
import assert from "node:assert";
import util from "node:util";
console.log("Testing")
test("[af5a2178] - SensitiveString Hides value by default", () => {
    const ss = new SensitiveString("foo");
    const expected = "sha256:2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
    assert.equal(ss.toString(), expected);
    assert.equal(ss.toLocaleString(), expected);
    assert.equal(`${ss}`, expected);
    assert.equal(JSON.stringify({ ss }), JSON.stringify({ ss: expected }));
    assert.equal(util.format(ss), expected); // equivalent to console.log
});
var getClassOf = Function.prototype.call.bind(Object.prototype.toString);
test("[af5a2178] - SensitiveString allows access to value", () => {
    const ss = new SensitiveString("foo");
    const expected = "sha256:2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae";
    const obj = { ss, "b": "c" };
    assert.equal(ss.getValue(), "foo");
    assert.equal(JSON.stringify(obj, SensitiveString.UnsecuredJSONReplacer()), JSON.stringify({ ss: "foo", "b": "c" }));
  assert.equal(JSON.stringify(obj, SensitiveString.UnsecuredJSONReplacer((key:string, value:any) => value)), JSON.stringify({ ss: "foo", "b": "c" }));
    assert.equal(JSON.stringify(obj), JSON.stringify({ ss: expected, "b": "c" })); // make sure we did not modify obj
});
test("[666e8222] - SensitiveString ExtractValue can get value", () => {
    const ss = new SensitiveString("foo");
    const s = "notfoo";
    assert.equal(SensitiveString.ExtractValue(ss), "foo");
    assert.equal(SensitiveString.ExtractValue(s), "notfoo");
    assert.equal(SensitiveString.ExtractValue(undefined), undefined);
});
test("[3325a6ad] - SensitiveString ExtractRequiredValue can get value", () => {
    const ss = new SensitiveString("foo");
    const s = "notfoo";
    assert.equal(SensitiveString.ExtractRequiredValue(ss), "foo");
    assert.equal(SensitiveString.ExtractRequiredValue(s), "notfoo");
    assert.throws(() => SensitiveString.ExtractRequiredValue(undefined));
});
test("[a23eb5b8] - SensitiveString Sensitive can get a SensitiveString from SensitiveString or string or null", () => {
    const ss = new SensitiveString("foo");
    const s = "notfoo";
    assert.equal(SensitiveString.Sensitive(ss), ss);
    assert.deepEqual(SensitiveString.Sensitive(s), new SensitiveString("notfoo"));
    assert.equal(SensitiveString.Sensitive(undefined), undefined);
    assert.equal(SensitiveString.Sensitive(null), null);
});
test("[a23eb5b8] - SensitiveString IsSensitiveString can detect SensitiveString vs not-SensitiveString", () => {
    const ss = new SensitiveString("foo");
    const s = "notfoo";
    assert(SensitiveString.IsSensitiveString(ss));
    assert(!SensitiveString.IsSensitiveString(s));
});
test("[a23eb5b8] - SensitiveString IsSensitiveString can detect weird parallel SensitiveString class", () => {
    const makeWeirdSensitiveString = () => {
        class SensitiveString {
        }
        ;
        return new SensitiveString();
    };
    const ss = makeWeirdSensitiveString();
    assert(SensitiveString.IsSensitiveString(ss));
});
test("[088caed0] - SensitiveString allows access to value length", () => {
    const ss = new SensitiveString("foo");
    assert.equal(3, ss.length);
});
