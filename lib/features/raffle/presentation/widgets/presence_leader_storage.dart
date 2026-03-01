// En web exporta la implementación con localStorage; en móvil/desktop el stub (siempre líder).
export 'presence_leader_storage_stub.dart'
    if (dart.library.html) 'presence_leader_storage_web.dart';
