# APIKit

## Models

### Fields

This library makes use of [MagneticFields](https://github.com/sadawi/MagneticFields) for 
adding some useful model behavior.  Your model doesn't need to have any `Field` attributes, but you'll miss out 
on most of the functionality if it doesn't.

Quick example:

```swift
class Person: Model {
  let name = Field<String>()
  let tags = *Field<String>()
}

var person = Person()
person.name.value = "Bob"
person.tags.value = ["red", "blue", "green"]
```

You should make your fields `let` constants, and set values through the `value` property, in order for change observation 
and validation to work properly.


### Identifiers

For consistency, all models have a `String?` `identifier` property.  It is expected to be computed from a field 
of either `String` or `Int` type, which you can specify by overriding the `identifierField` var.  
By default, it'll be `nil`.

### Validation

TODO

### Serialization

All models automatically convert to and from a dictionary representation through the `dictionaryValue` property.

Dictionary keys default to a string version of each field's property name, but you can customize it by specifying a 
`key` initialization argument.  

```swift
let firstName = Field<String>(key: "first_name")
```

By default, values are simply cast between `AnyObject` and the field's value type.  More complicated transformations 
can be specified on the field by adding a transformer (see the [MagneticFields](https://github.com/sadawi/MagneticFields) 
docs for full details):

```swift
let birthday = Field<NSDate>().transform(MyCustomDateTransformer())
```

If your field's value is a subclass of `Model`, the `ModelField` subclass automatically uses `ModelValueTransformer`:

```swift
let companies = *ModelField<Company>()
```

## Data Stores

TODO
