#!/usr/bin/env python3
import asyncio
from mavsdk import System
import math
import time

async def main():
    # Conecta no PX4 SITL padrão (UDP)
    drone = System()
    await drone.connect(system_address="udp://:14540")

    print(">> aguardando conexão com o veículo...")
    async for state in drone.core.connection_state():
        if state.is_connected:
            print("conectado ao PX4")
            break

    # Espera ter global position ok e home position válida
    print(">> aguardando GPS/local position saudável...")
    async for health in drone.telemetry.health():
        if health.is_global_position_ok and health.is_home_position_ok:
            print("posição ok, podemos voar")
            break

    # Armar
    print(">> armando motores")
    await drone.action.arm()

    # Decolar para 3m AGL
    target_alt_m = 2.5
    print(f">> decolando para {target_alt_m} m")
    await drone.action.takeoff()

    # Espera subir até perto da altitude alvo
    async for position in drone.telemetry.position():
        rel_alt = position.relative_altitude_m
        print(f"altitude atual: {rel_alt:.2f} m")
        if rel_alt >= target_alt_m * 0.9:
            print("altitude alvo atingida")
            break
        await asyncio.sleep(0.2)

    # Mantém hover um pouquinho
    print(">> mantendo hover 5s")
    await asyncio.sleep(5)

    # Pouso
    print(">> pousando")
    await drone.action.land()

    # Esperar encostar (altitude ~0.1 m e motors desarmam)
    landed = False
    async for in_air in drone.telemetry.in_air():
        if not in_air:
            landed = True
            print("pousado e motores desarmados")
            break
        await asyncio.sleep(0.5)

    if not landed:
        print("não consegui confirmar pouso pelo in_air")

if __name__ == "__main__":
    asyncio.run(main())
