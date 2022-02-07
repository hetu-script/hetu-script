import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    class Animal {
      fun walk {
        print('animal walking')
      }

      var kind

      construct (kind) {
        this.kind = kind
      }
    }

    class Bird extends Animal {
      fun animalWalk {
        // You can access a overrided member in super class by the super keyword within a method body.
        super.walk()
      }
      // override super class's member
      fun walk {
        print('bird walking')
      }
      fun fly {
        print('bird flying')
      }

      // You can use super class's constructor by the super keyword after a constructor declaration.
      construct _: super('bird')

      // factory is a special kind of contructor that returns values.
      // factory are static and cannot directly access instance members and constructors.
      factory {
        return Bird._()
      }
    }
    final b = Bird()
    b.walk()
  ''');
}
