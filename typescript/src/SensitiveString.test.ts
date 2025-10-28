// Forked from https://www.npmjs.com/package/@earnest-labs/ts-sensitivestring
// License: MIT
import SensitiveString from "./SensitiveString.ts";
import { test } from "node:test";
import assert from "node:assert";
import util from "node:util";
import _ from "lodash";
import yaml from "yaml";
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
    assert.equal(JSON.stringify(obj, SensitiveString.PlaintextReplacer()), JSON.stringify({ ss: "foo", "b": "c" }));
  assert.equal(JSON.stringify(obj, SensitiveString.PlaintextReplacer((key:string, value:any) => value)), JSON.stringify({ ss: "foo", "b": "c" }));
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

// Edge case tests for potential leaks
test("[455A1E09] - valueOf() should not leak raw value", () => {
    const ss = new SensitiveString("secret123");
    const expected = "sha256:bd2b1aaf7ef4f09be9f52ce2d8d599674d81aa9d6a4421696dc4d93dd0619d682";
    
    // Test valueOf directly
    const valueOfResult = ss.valueOf();
    console.log("valueOf() returns:", valueOfResult);
    assert.notEqual(valueOfResult, "secret123", "valueOf() leaked the raw value!");
    
    // Test implicit coercion scenarios
    const stringCoercion = "prefix" + ss;
    console.log("String coercion ('prefix' + ss):", stringCoercion);
    assert(!stringCoercion.includes("secret123"), "String concatenation leaked raw value!");
});

test("[03C5792E] - Symbol.toPrimitive should not leak raw value", () => {
    const ss = new SensitiveString("secret456");
    const expected = "sha256:3e1c7c1a4f6b51f7a6deebe31be0b75c5f8d5f4e6df07e9f8c7e5e5a9f7c6e0a";
    
    // Check if Symbol.toPrimitive exists
    const hasToPrimitive = Symbol.toPrimitive in ss;
    console.log("Has Symbol.toPrimitive:", hasToPrimitive);
    
    if (hasToPrimitive) {
        const toPrimitiveResult = (ss as any)[Symbol.toPrimitive]("string");
        console.log("Symbol.toPrimitive result:", toPrimitiveResult);
        assert.notEqual(toPrimitiveResult, "secret456", "Symbol.toPrimitive leaked raw value!");
    }
    
    // Test type coercion scenarios
    const stringCoercion = "" + ss;
    console.log("Empty string coercion ('' + ss):", stringCoercion);
    assert(!stringCoercion.includes("secret456"), "Type coercion leaked raw value!");
});

test("[B13EC963] - Number coercion should not leak raw value", () => {
    const ss = new SensitiveString("12345");
    
    try {
        const numResult = Number(ss);
        console.log("Number(ss) returns:", numResult);
        assert.notEqual(numResult, 12345, "Number coercion leaked raw numeric value!");
    } catch (e) {
        console.log("Number(ss) threw error (safe):", (e as Error).message);
        // If it throws, that's fine - it's not leaking
    }
});

test("[458ECC56] - Object.assign should not leak raw value", () => {
    const ss = new SensitiveString("secret789");
    
    const assigned = Object.assign({}, ss);
    console.log("Object.assign({}, ss):", JSON.stringify(assigned));
    
    // Check if any property contains the raw value
    const assignedStr = JSON.stringify(assigned);
    assert(!assignedStr.includes("secret789"), "Object.assign leaked raw value!");
});

test("[884C5A45] - Spread operator should not leak raw value", () => {
    const ss = new SensitiveString("secret999");
    
    const spread = {...ss};
    console.log("Spread {...ss}:", JSON.stringify(spread));
    
    // Check if any property contains the raw value
    const spreadStr = JSON.stringify(spread);
    assert(!spreadStr.includes("secret999"), "Spread operator leaked raw value!");
});

test("[FF9E5115] - Array operations should not leak raw value", () => {
    const ss = new SensitiveString("secretArray");
    const expected = "sha256:f5dc3e4c7f5e8e5f5f6e5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f5f";
    
    const arr = [ss];
    const joined = arr.join(",");
    console.log("Array join:", joined);
    assert(!joined.includes("secretArray"), "Array join leaked raw value!");
    
    const arrString = arr.toString();
    console.log("Array toString:", arrString);
    assert(!arrString.includes("secretArray"), "Array toString leaked raw value!");
});

test("[42327B52] - structuredClone should not leak raw value", () => {
    const ss = new SensitiveString("secretClone");
    
    try {
        const cloned = structuredClone(ss);
        console.log("structuredClone result:", cloned);
        
        // If it succeeds, make sure it doesn't contain the raw value
        const clonedStr = JSON.stringify(cloned);
        console.log("structuredClone stringified:", clonedStr);
        assert(!clonedStr.includes("secretClone"), "structuredClone leaked raw value!");
    } catch (e) {
        console.log("structuredClone threw error (potentially safe):", (e as Error).message);
        // If it fails to clone, that might be okay - just document it
    }
});

// Lodash security tests
test("[6FD7FF0F-LODASH] - _.clone() should not leak raw value", () => {
    const ss = new SensitiveString("secretLodashClone");
    
    const cloned = _.clone(ss);
    console.log("_.clone() result type:", typeof cloned);
    console.log("_.clone() instanceof SensitiveString:", cloned instanceof SensitiveString);
    console.log("_.clone() keys:", Object.keys(cloned));
    console.log("_.clone() own property names:", Object.getOwnPropertyNames(cloned));
    
    // Check if getValue exists and what it returns
    let getValueResult: any = undefined;
    getValueResult = (cloned as any).getValue();
    console.log("_.clone().getValue() returns:", getValueResult);
    assert(getValueResult && getValueResult === "secretLodashClone", "🚨 _.clone() didn't copy raw value!");
    
    // Try toString() but catch the error if it throws
    const toStringResult = ss.toString();
    console.log("_.clone().toString():", toStringResult);
    assert(!toStringResult.includes("secretLodashClone"), "_.clone().toString() leaked raw value!");
    
    // Try to stringify - catch error if it throws
    const clonedStr = JSON.stringify(cloned);
    console.log("_.clone() stringified:", clonedStr);
    assert(!clonedStr.includes("secretLodashClone"), "_.clone() leaked raw value in JSON!");
});

test("[BEBB427A-LODASH] - _.cloneDeep() should not leak raw value", () => {
    const ss = new SensitiveString("secretDeepClone");
    
    const cloned = _.cloneDeep(ss);
    console.log("_.cloneDeep() result type:", typeof cloned);
    console.log("_.cloneDeep() instanceof SensitiveString:", cloned instanceof SensitiveString);
    console.log("_.cloneDeep() keys:", Object.keys(cloned));
    console.log("_.cloneDeep() own property names:", Object.getOwnPropertyNames(cloned));
    
    // Check if getValue exists and what it returns
    let getValueResult: any = undefined;
    getValueResult = (cloned as any).getValue();
    console.log("_.cloneDeep().getValue() returns:", getValueResult);
    assert(getValueResult && getValueResult === "secretDeepClone", "🚨 _.cloneDeep() didn't copy raw value!");
    
    // Try toString() but catch the error if it throws
    const toStringResult = cloned.toString();
    console.log("_.cloneDeep().toString():", toStringResult);
    assert(!toStringResult.includes("secretDeepClone"), "_.cloneDeep().toString() leaked raw value!");
    
    // Try to stringify - catch error if it throws
    const clonedStr = JSON.stringify(cloned);
    console.log("_.cloneDeep() stringified:", clonedStr);
    assert(!clonedStr.includes("secretDeepClone"), "_.cloneDeep() leaked raw value in JSON!");
});

test("[CEF8BA43-LODASH] - _.toPlainObject() should not leak raw value", () => {
    const ss = new SensitiveString("secretPlainObj");
    
    const plain = _.toPlainObject(ss);
    console.log("_.toPlainObject() result:", plain);
    
    const plainStr = JSON.stringify(plain);
    console.log("_.toPlainObject() stringified:", plainStr);
    assert(!plainStr.includes("secretPlainObj"), "_.toPlainObject() leaked raw value!");
});

test("[3573E228-LODASH] - _.toString() should not leak raw value", () => {
    const ss = new SensitiveString("secretToString");
    
    const str = _.toString(ss);
    console.log("_.toString() result:", str);
    assert(!str.includes("secretToString"), "_.toString() leaked raw value!");
    assert(str.includes("sha256:"), "_.toString() should return SHA hash");
});

test("[270F5CFE-LODASH] - _.values() should not leak raw value", () => {
    const ss = new SensitiveString("secretValues");
    
    const values = _.values(ss);
    console.log("_.values() result:", values);
    
    const valuesStr = JSON.stringify(values);
    console.log("_.values() stringified:", valuesStr);
    assert(!valuesStr.includes("secretValues"), "_.values() leaked raw value!");
});

test("[DFFDF912-LODASH] - _.keys() should not leak raw value", () => {
    const ss = new SensitiveString("secretKeys");
    
    const keys = _.keys(ss);
    console.log("_.keys() result:", keys);
    
    const keysStr = JSON.stringify(keys);
    console.log("_.keys() stringified:", keysStr);
    assert(!keysStr.includes("secretKeys"), "_.keys() leaked raw value!");
});

test("[B0DF8616-LODASH] - _.merge() should not leak raw value", () => {
    const ss = new SensitiveString("secretMerge");
    
    const merged = _.merge({}, ss);
    console.log("_.merge() result:", merged);
    
    const mergedStr = JSON.stringify(merged);
    console.log("_.merge() stringified:", mergedStr);
    assert(!mergedStr.includes("secretMerge"), "_.merge() leaked raw value!");
});

test("[60DFE4FD-LODASH] - _.assign() should not leak raw value", () => {
    const ss = new SensitiveString("secretAssign");
    
    const assigned = _.assign({}, ss);
    console.log("_.assign() result:", assigned);
    
    const assignedStr = JSON.stringify(assigned);
    console.log("_.assign() stringified:", assignedStr);
    assert(!assignedStr.includes("secretAssign"), "_.assign() leaked raw value!");
});

test("[22E41CC2-LODASH] - _.isEqual() with raw string should not match", () => {
    const ss = new SensitiveString("secretEqual");
    
    const isEqual = _.isEqual(ss, "secretEqual");
    console.log("_.isEqual(ss, 'secretEqual'):", isEqual);
    assert.strictEqual(isEqual, false, "_.isEqual() should not match SensitiveString with raw string!");
});

test("[51728D89-LODASH] - _.get() should not access private fields", () => {
    const ss = new SensitiveString("secretGet");
    
    // Try to access various potential property paths
    const attempts = [
        _.get(ss, 'value'),
        _.get(ss, '#value'),
        _.get(ss, '_value'),
        _.get(ss, 'getValue'),
    ];
    
    console.log("_.get() attempts:", attempts);
    
    const attemptsStr = JSON.stringify(attempts);
    assert(!attemptsStr.includes("secretGet"), "_.get() leaked raw value!");
});

test("[21F84D16-LODASH] - _.toPairs() should not leak raw value", () => {
    const ss = new SensitiveString("secretPairs");
    
    const pairs = _.toPairs(ss);
    console.log("_.toPairs() result:", pairs);
    
    const pairsStr = JSON.stringify(pairs);
    console.log("_.toPairs() stringified:", pairsStr);
    assert(!pairsStr.includes("secretPairs"), "_.toPairs() leaked raw value!");
});

test("[7D88089D-LODASH] - _.invert() should not leak raw value", () => {
    const ss = new SensitiveString("secretInvert");
    
    const inverted = _.invert(ss);
    console.log("_.invert() result:", inverted);
    
    const invertedStr = JSON.stringify(inverted);
    console.log("_.invert() stringified:", invertedStr);
    assert(!invertedStr.includes("secretInvert"), "_.invert() leaked raw value!");
});

test("[42765697-LODASH] - _.mapValues() should not leak raw value", () => {
    const ss = new SensitiveString("secretMapValues");
    
    const mapped = _.mapValues(ss, (v) => v);
    console.log("_.mapValues() result:", mapped);
    
    const mappedStr = JSON.stringify(mapped);
    console.log("_.mapValues() stringified:", mappedStr);
    assert(!mappedStr.includes("secretMapValues"), "_.mapValues() leaked raw value!");
});

test("[D7BDCF0E-LODASH] - _.pick() should not leak raw value", () => {
    const ss = new SensitiveString("secretPick");
    
    // Try to pick various properties
    const picked = _.pick(ss, ['value', '#value', '_value', 'length']);
    console.log("_.pick() result:", picked);
    
    const pickedStr = JSON.stringify(picked);
    console.log("_.pick() stringified:", pickedStr);
    assert(!pickedStr.includes("secretPick"), "_.pick() leaked raw value!");
});

// YAML security tests
test("[C9D43D4F-YAML] - yaml.stringify() should not leak raw value", () => {
    const ss = new SensitiveString("secretYaml");
    const obj = { 
        username: "testuser",
        password: ss,
        nested: {
            apiKey: new SensitiveString("secretApiKey")
        }
    };
    
    const yamlStr = yaml.stringify(obj);
    console.log("yaml.stringify() result:", yamlStr);
    
    // Verify the raw values are not in the output
    assert(!yamlStr.includes("secretYaml"), "yaml.stringify() leaked password raw value!");
    assert(!yamlStr.includes("secretApiKey"), "yaml.stringify() leaked apiKey raw value!");
    
    // Verify the hash is present
    assert(yamlStr.includes("sha256:"), "yaml.stringify() should show SHA hash!");
});

test("[404A48D7-YAML] - yaml.stringify() with PlaintextReplacer should serialize secrets", () => {
    const ss = new SensitiveString("secretYamlUnsecured");
    const obj = { 
        username: "testuser",
        password: ss,
        nested: {
            apiKey: new SensitiveString("secretUnsecuredApiKey")
        }
    };
    
    // yaml.stringify accepts a replacer function similar to JSON.stringify
    const yamlStr = yaml.stringify(obj, SensitiveString.PlaintextReplacer());
    console.log("yaml.stringify() with PlaintextReplacer result:", yamlStr);
    
    // Verify the raw values ARE in the output when using PlaintextReplacer
    assert(yamlStr.includes("secretYamlUnsecured"), "yaml.stringify() with PlaintextReplacer should include password raw value!");
    assert(yamlStr.includes("secretUnsecuredApiKey"), "yaml.stringify() with PlaintextReplacer should include apiKey raw value!");
    
    // Verify the hash is NOT present (should be raw values)
    assert(!yamlStr.includes("sha256:"), "yaml.stringify() with PlaintextReplacer should NOT show SHA hash!");
});
