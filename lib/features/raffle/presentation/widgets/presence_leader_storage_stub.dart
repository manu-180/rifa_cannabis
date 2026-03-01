// En móvil/desktop hay una sola instancia = un dispositivo. Siempre "líder".
bool presenceAmILeader() => true;
bool presenceTryClaimLeader() => true;
void presenceHeartbeatTick(void Function() onBecameLeader) {}
