"use client"

import { useRef } from "react"
import { Canvas } from "@react-three/fiber"
import { OrbitControls, Environment, PerspectiveCamera } from "@react-three/drei"
import * as THREE from "three"
import type { GemPattern } from "@/lib/gem-patterns"

interface Gem3DViewerProps {
  pattern: GemPattern
  currentFacet?: number
  showLabels?: boolean
}

function LaserCuttingLine({
  position,
  rotation,
  isActive,
}: { position: [number, number, number]; rotation: [number, number, number]; isActive: boolean }) {
  return (
    <group position={position} rotation={rotation}>
      {/* Laser cutting plane */}
      <mesh>
        <planeGeometry args={[80, 80]} />
        <meshBasicMaterial
          color={isActive ? "#3b82f6" : "#60a5fa"}
          transparent
          opacity={isActive ? 0.3 : 0.1}
          side={2}
        />
      </mesh>
      {/* Laser grid lines */}
      <lineSegments>
        <edgesGeometry args={[new THREE.PlaneGeometry(80, 80, 8, 8)]} />
        <lineBasicMaterial
          color={isActive ? "#3b82f6" : "#60a5fa"}
          linewidth={2}
          transparent
          opacity={isActive ? 0.8 : 0.3}
        />
      </lineSegments>
      {/* Bright laser edge */}
      <mesh position={[0, 0, 0.1]}>
        <ringGeometry args={[35, 40, 32]} />
        <meshBasicMaterial color="#3b82f6" transparent opacity={isActive ? 0.6 : 0.2} />
      </mesh>
    </group>
  )
}

function GemModel({ pattern, currentFacet }: { pattern: GemPattern; currentFacet?: number }) {
  const groupRef = useRef<THREE.Group>(null)

  return (
    <group ref={groupRef}>
      {/* Main gem body - faceted diamond */}
      <mesh position={[0, 0, 0]} castShadow receiveShadow>
        <octahedronGeometry args={[35, 2]} />
        <meshPhysicalMaterial
          color="#dbeafe"
          metalness={0.1}
          roughness={0.05}
          transmission={0.9}
          thickness={15}
          transparent
          opacity={0.8}
          clearcoat={1}
          clearcoatRoughness={0.1}
          ior={2.4}
        />
      </mesh>

      {/* Gem highlights */}
      <mesh position={[0, 0, 0]} scale={0.95}>
        <octahedronGeometry args={[35, 2]} />
        <meshBasicMaterial color="#3b82f6" transparent opacity={0.1} side={2} />
      </mesh>

      {pattern.facets.slice(0, Math.min(3, (currentFacet ?? 0) + 1)).map((facet, index) => {
        const angleRad = (facet.angle * Math.PI) / 180
        const rotationRad = (facet.rotation * Math.PI) / 180
        const yPos = -10 + index * 15

        return (
          <LaserCuttingLine
            key={facet.id}
            position={[0, yPos, 0]}
            rotation={[angleRad, rotationRad, 0]}
            isActive={index === currentFacet}
          />
        )
      })}

      {/* Measurement points */}
      {[...Array(8)].map((_, i) => {
        const angle = (i * Math.PI * 2) / 8
        const radius = 40
        return (
          <mesh key={i} position={[Math.cos(angle) * radius, 0, Math.sin(angle) * radius]}>
            <sphereGeometry args={[1.5, 8, 8]} />
            <meshBasicMaterial color="#3b82f6" transparent opacity={0.6} />
          </mesh>
        )
      })}
    </group>
  )
}

export function Gem3DViewer({ pattern, currentFacet, showLabels = true }: Gem3DViewerProps) {
  return (
    <div className="w-full h-full">
      <Canvas shadows gl={{ antialias: true, alpha: true }} dpr={[1, 2]}>
        <color attach="background" args={["#0a0a0a"]} />

        <PerspectiveCamera makeDefault position={[100, 60, 100]} fov={50} />

        <ambientLight intensity={0.4} />
        <directionalLight position={[10, 10, 5]} intensity={1.2} castShadow />
        <pointLight position={[0, 50, 0]} intensity={1} color="#3b82f6" />
        <pointLight position={[-50, 0, 50]} intensity={0.6} color="#60a5fa" />
        <pointLight position={[50, 0, -50]} intensity={0.6} color="#60a5fa" />

        <Environment preset="studio" />

        <GemModel pattern={pattern} currentFacet={currentFacet} />

        {/* Platform with measurement grid */}
        <mesh position={[0, -45, 0]} rotation={[-Math.PI / 2, 0, 0]} receiveShadow>
          <planeGeometry args={[120, 120, 12, 12]} />
          <meshStandardMaterial color="#0f172a" metalness={0.2} roughness={0.8} wireframe wireframeLinewidth={0.5} />
        </mesh>

        <mesh position={[0, -45.5, 0]} rotation={[-Math.PI / 2, 0, 0]} receiveShadow>
          <circleGeometry args={[60, 64]} />
          <meshStandardMaterial color="#1e293b" metalness={0.5} roughness={0.5} />
        </mesh>

        <OrbitControls
          makeDefault
          enableDamping
          dampingFactor={0.05}
          rotateSpeed={0.5}
          minDistance={80}
          maxDistance={250}
        />
      </Canvas>
    </div>
  )
}
