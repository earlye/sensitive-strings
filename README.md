# SensitiveStrings

SensitiveStrings are a conceptual type for strings containing
_secrets_, which are values that you don't want to _accidentally_
persist. Accidental persistence happens, for example, when you JSON
encode objects containing a secret without stopping to think about the
fact that there is a secret there.

A typescript example of a bad situation:

```typescript
const credentials = { username: "earlye@gmail.com" , password: "2CBD047F-005C-4DC6-AE66-5B9D8C1E709F" };
// later
console.log( credentials ) // WELL, THAT'S NOT GOOD.
```

A better example:
```typescript
const credentials = { username: SensitiveString.Sensitive("earlye@gmail.com"), password: SensitiveString.Sensitive("2CBD047F-005C-4DC6-AE66-5B9D8C1E709F") };
// later
console.log( credentials ) // {username: "SHA...", password: "SHA..."}
```

This repo is intended to house a collection of SensitiveString
implementations in various languages.  We start with typescript, and
in past day-jobs have implemented SensitiveString in a wide array of
languages including Go, Python, and C++.

The main idea is that writing a SensitiveString instance to some
persistent location (database, stdout, some JSON string, etc) should
BY DEFAULT actually write a sha256 hash for the underlying value, so
that you can (a) see that there is a SensitiveString, and (b) if
necessary, write a known value locally in order to compare the sha
against what you're seeing in logs. The reason for (b) is that
sometimes it's useful to be able to see the hashed value for debugging
purposes.

The interface for SensitiveString should make sense in each language
where it is implemented, so this doc won't detail that interface. See
the code for the specific language implementation you're interested in.