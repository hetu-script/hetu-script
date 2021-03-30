import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    var globalController = GlobalController()
    class Host {
      var name: str
      construct(name: str) {
        this.name = name
      }
    }

    fun _rebuild(host) {
      print('_rebuild called on', host.name)
    }

    class Widget {
      var host: Host
      fun rebuild {
        _rebuild(host)
      }
    }

    class ScriptWidget extends Widget {
      construct(host: Host) {
        this.host = host
        globalController.addListener(
          fun {
            rebuild()
          }
        )
      }
    }

    class GlobalController {
      var listeners: List = []
      fun addListener(listener) {
        listeners.add(listener)
      }
      fun fireEvent() {
        for (var listener in listeners) {
          listener()
        }
      }
    }
    fun main {
      var widget = ScriptWidget(Host('widget host'))
      globalController.fireEvent()
    }

  ''', invokeFunc: 'main');
}
