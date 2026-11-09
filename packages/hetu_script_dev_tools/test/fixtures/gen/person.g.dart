// GENERATED CODE - DO NOT MODIFY BY HAND
// Binding for D:\_dev\hetu-script\packages\hetu_script_dev_tools\test\fixtures\person.dart

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import '../person.dart';

class IngredientsClassBinding extends HTExternalClass {
  IngredientsClassBinding() : super('Ingredients');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Ingredients.values':
        return Ingredients.values;
      case 'Ingredients.Apple':
        return Ingredients.Apple;
      case 'Ingredients.Banana':
        return Ingredients.Banana;
      case 'Ingredients.Cinnamon':
        return Ingredients.Cinnamon;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Ingredients;
    switch (id) {
      case 'index':
        return object.index;
      case 'name':
        return object.name;
      case 'toString':
        return ({positionalArgs, namedArgs}) => object.toString();
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}

class PersonClassBinding extends HTExternalClass {
  PersonClassBinding() : super('Person');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    switch (id) {
      case 'Person':
        return ({positionalArgs, namedArgs}) => Person(
            positionalArgs.length > 0 ? positionalArgs[0] : 'Jimmy',
            positionalArgs.length > 1 ? positionalArgs[1] : 'Caucasian');
      case 'Person.withName':
        return ({positionalArgs, namedArgs}) => Person.withName(
            positionalArgs[0],
            positionalArgs.length > 1 ? positionalArgs[1] : 'Caucasian');
      case 'Person.meaning':
        return ({positionalArgs, namedArgs}) =>
            Person.meaning(positionalArgs[0]);
      case 'Person.level':
        return Person.level;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  void memberSet(String id, dynamic value,
      {String? from, bool defineIfAbsent = false}) {
    switch (id) {
      case 'Person.level':
        Person.level = value;
      default:
        throw HTError.undefined(id);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final object = instance as Person;
    switch (id) {
      case 'greeting':
        return ({object, positionalArgs, namedArgs}) =>
            object.greeting(positionalArgs[0]);
      case 'child':
        return object.child;
      case 'name':
        return object.name;
      case 'race':
        return object.race;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  void instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    final object = instance as Person;
    switch (id) {
      case 'name':
        object.name = value;
      case 'race':
        object.race = value;
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }
}
