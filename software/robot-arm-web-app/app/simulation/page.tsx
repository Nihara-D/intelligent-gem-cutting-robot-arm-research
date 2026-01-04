"use client"

import { useState } from "react"
import { RobotArm3D } from "@/components/robot-arm-3d"
import { Gem3DViewer } from "@/components/gem-3d-viewer"
import { CuttingSequenceViewer } from "@/components/cutting-sequence-viewer"
import { PageHeader } from "@/components/page-header"
import { BottomNav } from "@/components/bottom-nav"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { GEM_PATTERNS } from "@/lib/gem-patterns"
import { Gem } from "lucide-react"

export default function SimulationPage() {
  const [selectedPattern, setSelectedPattern] = useState(GEM_PATTERNS[0])
  const [currentStep, setCurrentStep] = useState(0)
  const [isSimulating, setIsSimulating] = useState(false)

  return (
    <div className="min-h-screen bg-background text-foreground p-6 pb-32">
      <div className="max-w-[1920px] mx-auto space-y-6">
        <PageHeader title="Gazebo Synchronization" description="Real-time manipulator trajectory in Gazebo Harmony" />

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Main Gazebo Workspace Visualization */}
          <Card className="bg-card border-border overflow-hidden aspect-video relative group ring-1 ring-primary/20">
            <CardHeader className="absolute top-0 left-0 right-0 z-10 bg-gradient-to-b from-black/90 to-transparent p-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-mono flex items-center gap-2">
                  <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                  Gazebo Environment
                </CardTitle>
                <Badge variant="outline" className="border-primary/50 text-primary">
                  SYNC ACTIVE
                </Badge>
              </div>
            </CardHeader>
            <RobotArm3D jointAngles={{ joint1: 0, joint2: 0, joint3: 0, joint4: 0, joint5: 0, joint6: 0 }} />
          </Card>

          <Card className="bg-card border-border overflow-hidden aspect-video relative ring-1 ring-primary/10">
            <CardHeader className="absolute top-0 left-0 right-0 z-10 bg-gradient-to-b from-black/90 to-transparent p-4">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-mono text-primary flex items-center gap-2">
                  <Gem className="w-4 h-4" />
                  3D Gem Cutting Visualization
                </CardTitle>
                <div className="flex gap-2">
                  <Badge className="bg-primary/20 text-primary border-primary/30">FACET {currentStep + 1}</Badge>
                  <Badge variant="outline" className="border-blue-500/50 text-blue-400 text-xs">
                    {selectedPattern.facets[currentStep]?.angle}° @ {selectedPattern.facets[currentStep]?.rotation}°
                  </Badge>
                </div>
              </div>
            </CardHeader>
            {/* 3D Gem with laser cutting planes */}
            <Gem3DViewer pattern={selectedPattern} currentFacet={currentStep} />
          </Card>
        </div>

        {/* Playback Controls and ROS Log */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <Card className="md:col-span-2 bg-card border-border">
            <CardContent className="p-6">
              {/* Simulation Controls */}
              <CuttingSequenceViewer
                pattern={selectedPattern}
                currentStep={currentStep}
                onStepChange={setCurrentStep}
                isPlaying={isSimulating}
                onPlayPause={() => setIsSimulating(!isSimulating)}
              />
            </CardContent>
          </Card>

          <Card className="bg-black border-border overflow-hidden">
            <CardHeader className="py-3 border-b border-border bg-muted/50">
              <CardTitle className="text-[10px] font-mono uppercase tracking-widest opacity-70">
                ROS 2 Telemetry
              </CardTitle>
            </CardHeader>
            <CardContent className="p-4 font-mono text-[10px] text-blue-400/90 h-40 overflow-y-auto space-y-1">
              <div>[INFO] Trajectory node ready</div>
              <div>[DEBUG] Link 6 pose synced with Gazebo</div>
              <div>[INFO] Moving to Facet {currentStep + 1} position</div>
            </CardContent>
          </Card>
        </div>
      </div>
      <BottomNav />
    </div>
  )
}
