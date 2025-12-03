import React from 'react';
import { CodeArchitecture } from './components/AICodeGenerator';
import { Button } from './components/Button';
import { MockInterface } from './components/MockInterface';
import { Github, Box, Layers, Zap, MousePointer2, ArrowDown, Package, Copy, CheckCircle2, XCircle, Puzzle, Gamepad2, Workflow } from 'lucide-react';

const Features = () => (
  <div className="relative border-t border-zinc-800">
    <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-px bg-zinc-800">
      {[
        { icon: <Zap size={24} strokeWidth={1} />, title: "NATIVE SWIFT", desc: "Zero WebViews. Pure Metal-accelerated SwiftUI rendering engine." },
        { icon: <Layers size={24} strokeWidth={1} />, title: "NODE GRAPH", desc: "Directed acyclic graph architecture with cycle detection." },
        { icon: <Puzzle size={24} strokeWidth={1} />, title: "EXTENSIBLE", desc: "Protocol-oriented design for custom node types." },
        { icon: <MousePointer2 size={24} strokeWidth={1} />, title: "INTERACTIVE", desc: "Custom gesture recognizers for pan, zoom, and drag operations." }
      ].map((f, i) => (
        <div key={i} className="p-10 bg-[#09090b] hover:bg-[#050505] transition-colors group relative border-r border-zinc-800 last:border-r-0">
          <div className="mb-6 text-zinc-500 group-hover:text-white transition-colors">{f.icon}</div>
          <h3 className="text-sm font-bold text-white mb-3 font-sans uppercase tracking-widest">{f.title}</h3>
          <p className="text-sm text-zinc-500 leading-relaxed font-mono">{f.desc}</p>
        </div>
      ))}
    </div>
  </div>
);

const ComparisonTable = () => (
  <div className="border border-zinc-800 bg-[#0c0c0e]">
    <div className="grid grid-cols-3 border-b border-zinc-800 bg-zinc-900/20">
      <div className="p-4 text-xs font-bold text-zinc-500 uppercase tracking-widest">Feature</div>
      <div className="p-4 text-xs font-bold text-white uppercase tracking-widest border-l border-zinc-800 bg-zinc-900/40">WFKit</div>
      <div className="p-4 text-xs font-bold text-zinc-600 uppercase tracking-widest border-l border-zinc-800">Web-based</div>
    </div>
    {[
      { label: "Startup time", wf: "<50ms", web: "500ms+" },
      { label: "Memory footprint", wf: "12MB", web: "100MB+" },
      { label: "Offline support", wf: "Always", web: "Depends" },
      { label: "Native feel", wf: "100%", web: "Electron-ish" },
      { label: "Bundle size", wf: "2MB", web: "20MB+" },
    ].map((row, i) => (
      <div key={i} className="grid grid-cols-3 border-b last:border-b-0 border-zinc-800 hover:bg-white/5 transition-colors">
        <div className="p-4 text-xs font-mono text-zinc-400">{row.label}</div>
        <div className="p-4 text-xs font-mono text-white border-l border-zinc-800 font-bold bg-white/5">{row.wf}</div>
        <div className="p-4 text-xs font-mono text-zinc-600 border-l border-zinc-800">{row.web}</div>
      </div>
    ))}
  </div>
);

const UseCases = () => (
  <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
    {[
      { title: "AI Workflows", icon: <Workflow size={20}/>, desc: "Build visual agent orchestration tools with drag-and-drop simplicity." },
      { title: "Data Pipelines", icon: <Layers size={20}/>, desc: "Let users design ETL workflows without writing code." },
      { title: "Automation", icon: <Zap size={20}/>, desc: "Create Shortcuts-like experiences in your own apps." },
      { title: "Game Logic", icon: <Gamepad2 size={20}/>, desc: "Visual scripting for game designers and modders." },
    ].map((useCase, i) => (
      <div key={i} className="border border-zinc-800 p-6 bg-[#0c0c0e] hover:border-zinc-600 transition-colors">
        <div className="mb-4 text-zinc-400">{useCase.icon}</div>
        <h4 className="text-sm font-bold text-white mb-2 uppercase tracking-wide">{useCase.title}</h4>
        <p className="text-xs text-zinc-500 font-mono leading-relaxed">{useCase.desc}</p>
      </div>
    ))}
  </div>
);

const Navbar = () => (
  <nav className="fixed top-0 left-0 right-0 z-50 bg-[#09090b]/90 backdrop-blur-md border-b border-zinc-800">
    <div className="max-w-[1400px] mx-auto px-6 h-16 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <div className="w-8 h-8 bg-white flex items-center justify-center">
          <Box size={16} className="text-black" strokeWidth={3} />
        </div>
        <span className="font-sans font-bold text-lg tracking-tighter text-white">WFKit</span>
      </div>
      <div className="hidden md:flex items-center gap-8">
        <a href="#" className="text-xs font-bold uppercase tracking-widest text-zinc-500 hover:text-white transition-colors">Documentation</a>
        <a href="#" className="text-xs font-bold uppercase tracking-widest text-zinc-500 hover:text-white transition-colors">Examples</a>
        <div className="h-4 w-[1px] bg-zinc-800"></div>
        <a href="#" className="text-zinc-500 hover:text-white transition-colors flex items-center gap-2">
            <span className="text-xs font-bold uppercase tracking-widest">GitHub</span>
            <Github size={16} />
        </a>
      </div>
    </div>
  </nav>
);

const Footer = () => (
  <footer className="border-t border-zinc-800 bg-[#050505] py-20 mt-20 relative">
    <div className="max-w-[1400px] mx-auto px-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-10">
       <div className="flex flex-col gap-4">
         <div className="flex items-center gap-2">
            <Box size={20} className="text-white" />
            <span className="font-sans font-bold text-xl text-white tracking-tighter">WFKit</span>
         </div>
         <p className="text-zinc-600 text-xs font-mono max-w-xs">
           A professional-grade workflow visualization library for the Swift ecosystem.
         </p>
      </div>
      
      <div className="flex gap-12">
        <div className="flex flex-col gap-4">
          <h4 className="font-bold text-white text-xs uppercase tracking-widest">Project</h4>
          <a href="#" className="text-zinc-600 hover:text-white text-xs font-mono transition-colors">Source Code</a>
          <a href="#" className="text-zinc-600 hover:text-white text-xs font-mono transition-colors">License (MIT)</a>
          <a href="#" className="text-zinc-600 hover:text-white text-xs font-mono transition-colors">Releases</a>
        </div>
        <div className="flex flex-col gap-4">
          <h4 className="font-bold text-white text-xs uppercase tracking-widest">Community</h4>
          <a href="#" className="text-zinc-600 hover:text-white text-xs font-mono transition-colors">Discussions</a>
          <a href="#" className="text-zinc-600 hover:text-white text-xs font-mono transition-colors">Issues</a>
          <a href="#" className="text-zinc-600 hover:text-white text-xs font-mono transition-colors">Twitter</a>
        </div>
      </div>
    </div>
  </footer>
);

export default function App() {
  return (
    <div className="min-h-screen bg-[#09090b] selection:bg-white selection:text-black font-mono flex flex-col">
      <Navbar />
      
      <main className="flex-1 pt-32 pb-20 px-6 max-w-[1400px] mx-auto w-full">
        
        {/* Hero Section */}
        <div className="grid lg:grid-cols-12 gap-12 lg:gap-24 items-center mb-40 border-b border-zinc-800 pb-20 relative">

          <div className="lg:col-span-5 relative z-10">
             <div className="inline-flex items-center gap-2 mb-8 border border-zinc-800 px-3 py-1 rounded-full bg-zinc-900/50">
               <div className="w-1.5 h-1.5 bg-green-500 rounded-full animate-pulse"></div>
               <span className="text-[10px] font-bold uppercase tracking-widest text-zinc-400">MIT License</span>
             </div>
             
             <h1 className="text-6xl md:text-8xl font-bold text-white mb-8 tracking-tighter leading-[0.85] font-sans">
               NATIVE<br/>
               FLOW<br/>
               ENGINE<span className="text-zinc-600">.</span>
             </h1>
             
             <p className="text-lg text-zinc-400 mb-10 max-w-md leading-relaxed font-light font-sans">
               Bring React Flow-like node editing to your native macOS and iOS apps. 
               Zero dependencies. Pure SwiftUI.
             </p>
             
             <div className="flex flex-col sm:flex-row items-start sm:items-center gap-6">
               <Button size="lg" icon={<Package size={16}/>}>ADD PACKAGE</Button>
               <Button size="lg" variant="outline" icon={<ArrowDown size={16}/>}>READ THE DOCS</Button>
             </div>
             
             <div className="mt-16 border-t border-zinc-800 pt-6 flex flex-wrap items-center gap-4 text-[10px] text-zinc-600 uppercase tracking-widest font-bold">
                <span className="flex items-center gap-2">
                  <div className="w-1.5 h-1.5 bg-zinc-500"></div> iOS 16+
                </span>
                <span className="text-zinc-800">/</span>
                <span className="flex items-center gap-2">
                  <div className="w-1.5 h-1.5 bg-zinc-500"></div> macOS 13+
                </span>
                <span className="text-zinc-800">/</span>
                <span>Swift 5.9</span>
             </div>
          </div>

          {/* Graphic / Screenshot Area */}
          <div className="lg:col-span-7 relative">
            <div className="relative border border-zinc-800 bg-[#0c0c0e] p-2 group">
              {/* Technical markers */}
              <div className="absolute top-0 left-0 w-4 h-4 border-t border-l border-white z-20"></div>
              <div className="absolute top-0 right-0 w-4 h-4 border-t border-r border-white z-20"></div>
              <div className="absolute bottom-0 left-0 w-4 h-4 border-b border-l border-white z-20"></div>
              <div className="absolute bottom-0 right-0 w-4 h-4 border-b border-r border-white z-20"></div>
              
              <div className="relative aspect-[16/10] overflow-hidden bg-[#0c0c0e] border border-zinc-800/50">
                 <MockInterface />
                 
                 <div className="absolute bottom-6 right-6 px-4 py-2 bg-black border border-zinc-800 flex items-center gap-4 z-20">
                    <div className="flex items-center gap-2">
                       <div className="w-1.5 h-1.5 bg-green-500 animate-pulse"></div>
                       <span className="text-[10px] text-zinc-300 font-bold uppercase tracking-wider">SwiftUI Preview</span>
                    </div>
                    <span className="text-[10px] text-zinc-600 font-mono">120 FPS</span>
                 </div>
              </div>
            </div>
            
            {/* Background decorative element */}
            <div className="absolute -z-10 top-8 -right-8 w-full h-full border border-zinc-800/30 bg-[url('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSI4IiBoZWlnaHQ9IjgiPgo8cmVjdCB3aWR0aD0iOCIgaGVpZ2h0PSI4IiBmaWxsPSIjMTgxODFiIi8+CjxwYXRoIGQ9Ik0wIDBMOCA4Wk04IDBMMCA4WiIgc3Ryb2tlPSIjMjcyNzJhIiBzdHJva2Utd2lkdGg9IjEiLz4KPC9zdmc+')] opacity-40"></div>
          </div>
        </div>

        {/* Features Section */}
        <div className="mb-40">
          <div className="flex items-end justify-between mb-10">
            <h2 className="text-3xl font-bold text-white font-sans tracking-tight">SYSTEM_ARCHITECTURE</h2>
            <span className="text-xs font-bold text-zinc-600 uppercase tracking-widest">v1.0.0-beta.2</span>
          </div>
          <Features />
        </div>

        {/* Code Showcase Section */}
        <div className="mb-40 border border-zinc-800 bg-[#0c0c0e]">
          <div className="grid lg:grid-cols-12 min-h-[600px] h-full divide-x divide-zinc-800">
            
            {/* Text Panel */}
            <div className="lg:col-span-4 p-8 lg:p-12 flex flex-col justify-center relative bg-[#09090b]">
               <div className="w-10 h-10 border border-zinc-700 flex items-center justify-center mb-6">
                  <Box size={20} strokeWidth={1} />
               </div>
               <h2 className="text-3xl font-bold text-white font-sans tracking-tight mb-4">CODE-DRIVEN<br/>DEFINITION</h2>
               <p className="text-zinc-500 text-sm leading-relaxed mb-8">
                 Define your node graphs using a clear, type-safe Swift DSL. 
                 The view hierarchy is fully backed by code, allowing for powerful dynamic generation.
               </p>
               <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-white">
                  <ArrowDown size={14} />
                  <span>View DSL Syntax</span>
               </div>

               {/* Technical Hinge / Divider */}
               <div className="absolute top-1/2 -right-[11px] -translate-y-1/2 hidden lg:flex flex-col items-center z-10">
                  <div className="w-px h-16 bg-gradient-to-b from-transparent to-zinc-700"></div>
                  <div className="w-[20px] h-[20px] bg-[#0c0c0e] border border-zinc-600 rotate-45 flex items-center justify-center shadow-xl">
                     <div className="w-1.5 h-1.5 bg-white rounded-full"></div>
                  </div>
                  <div className="w-px h-16 bg-gradient-to-t from-transparent to-zinc-700"></div>
               </div>
            </div>

            {/* Code Panel */}
            <div className="lg:col-span-8 bg-[#0c0c0e]">
              <CodeArchitecture frameless />
            </div>
          </div>
        </div>

        {/* Comparison & Use Cases Grid */}
        <div className="mb-40 grid xl:grid-cols-12 gap-12">
           <div className="xl:col-span-5">
              <h2 className="text-2xl font-bold text-white font-sans tracking-tight mb-8">WHY WFKIT?</h2>
              <ComparisonTable />
           </div>
           <div className="xl:col-span-7">
              <h2 className="text-2xl font-bold text-white font-sans tracking-tight mb-8">USE CASES</h2>
              <UseCases />
           </div>
        </div>

        {/* Quick Install */}
        <div className="max-w-2xl mx-auto text-center border border-zinc-800 p-12 bg-[#0c0c0e] relative overflow-hidden">
           <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-white to-transparent opacity-20"></div>
           
           <h2 className="text-3xl font-bold text-white font-sans tracking-tight mb-6">START BUILDING</h2>
           <p className="text-zinc-500 mb-8 max-w-md mx-auto font-mono text-sm">
            Add the package to your project and import WFKit to get started instantly.
           </p>
           
           <div className="flex flex-col items-center gap-4">
              <div className="flex items-center bg-black border border-zinc-800 p-4 w-full max-w-lg group hover:border-zinc-600 transition-colors cursor-pointer" onClick={() => navigator.clipboard.writeText('.package(url: "https://github.com/wfkit/wfkit.git", from: "1.0.0")')}>
                 <span className="text-zinc-500 mr-4 select-none">$</span>
                 <code className="flex-1 text-left text-xs md:text-sm text-zinc-300 font-mono">
                   .package(url: "https://github.com/wfkit/wfkit.git", from: "1.0.0")
                 </code>
                 <Copy size={14} className="text-zinc-600 group-hover:text-white transition-colors" />
              </div>
              <span className="text-[10px] text-zinc-600 uppercase tracking-widest">Click to copy dependency</span>
           </div>
        </div>

      </main>
      
      <Footer />
    </div>
  );
}