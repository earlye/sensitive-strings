# SensitiveStrings

SensitiveStrings are a conceptual type for strings containing _secrets_, which are values that you don't want to _accidentally_ persist. Accidental persistence happens, for example, when you JSON encode objects containing a secret without stopping to think about the fact that there is a secret there.

A typescript example of a bad situation:

```typescript
const credentials = { username: "someone@gmail.com" , password: "2CBD047F-005C-4DC6-AE66-5B9D8C1E709F" };
// later
console.log( credentials ) // WELL, THAT'S NOT GOOD.
```

A better example:
```typescript
const credentials = { username: SensitiveString.Sensitive("someone@gmail.com"), password: SensitiveString.Sensitive("2CBD047F-005C-4DC6-AE66-5B9D8C1E709F") };
// later
console.log( credentials ) // {username: "SHA...", password: "SHA..."}
```

This package implements SensitiveString in Typescript.

The main idea is that writing a SensitiveString instance to some persistent location (database, stdout, some JSON string, etc) should BY DEFAULT actually write a sha256 hash for the underlying value, so that you can (a) see that there is a SensitiveString, and (b) if necessary, write a known value locally in order to compare the sha against what you're seeing in logs. The reason for (b) is that sometimes it's useful to be able to see the hashed value for debugging purposes.

The interface for SensitiveString should make sense in each language where it is implemented, so this doc won't detail that interface. See the code for the specific language implementation you're interested in.

# Typescript implementation details

- **Zero runtime dependencies**.
  - **Sha256 Hash Source** - We inlined sha256 from https://github.com/paulmillr/noble-hashes/ It only required adding a bunch of `!` postfix-operators to tell typescript that we trust that noble-hashes have done the work to make sure that possibly-undefined values are never _actually_ undefined. A special thanks to them. This does mean that as fixes to noble-hashes come out, we run the risk of falling behind. We've got it starred in github, but if you don't trust us, please feel free to submit PRs or issues when you see that we've fallen behind. (issues preferred - we'll re-inline it in that scenario from the original source, so your PR will just get thrown away. It's not that we don't trust _you_ individually, but we don't trust you in the sense of "you're on the internet, so we have to do due dilligence and checking a trusted source is easier than checking a PR")

- **Top-Level await required** - This module attempts to import some nodejs-specific modules in order to provide the method `[util.inspect.custom]()`, so that console.log in node js doesn't leak.

- **Transpiling is not yet done for you** - As I write this, we test in nodejs 24.9.0, using its type stripping, and using tsc --noEmit just to validate typings. We'll get to it and give you an actual npm package eventually. PRs welcome.

- **React has not been thoroughly tested**. Potential concerns:
  - **React DevTools**: Inspector might show internal state (needs manual verification)
  - **React Server Components (RSC)**: Server-to-client serialization needs testing (may bypass `toJSON()`)
  - **Forms**: Requires explicit `.getValue()` for controlled inputs (this is actually good - forces intentional access)
  - **Error boundaries** and deep comparison libraries might behave unpredictably
