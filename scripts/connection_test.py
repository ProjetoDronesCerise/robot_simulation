import asyncio
from mavsdk import System

async def main():
    drone = System()
    # aqui voce so abre a porta 14540 local e espera pacotes
    await drone.connect(system_address="udp://192.168.8.1:14540")

    print("Esperando heartbeat do drone...")

    async for state in drone.core.connection_state():
        if state.is_connected:
            print("Conectado ao drone!")
            break

    # pega uma info de telemetria leve e segura
    async for pos in drone.telemetry.position():
        print(f"Lat: {pos.latitude_deg}, Lon: {pos.longitude_deg}, Alt: {pos.relative_altitude_m} m")
        break

    async for batt in drone.telemetry.battery():
        print(f"Bateria: {batt.remaining_percent*100:.1f}%")
        break

if __name__ == "__main__":
    asyncio.run(main())
