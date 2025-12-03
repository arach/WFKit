import React, { useState } from 'react';
import { Terminal, Copy, Check, FileCode, Sliders, Database, Box, Cpu } from 'lucide-react';

const SNIPPETS = {
  'Workflow.swift': `import WFKit
import SwiftUI

struct DataProcessingWorkflow: View {
    @StateObject var store = CanvasState()

    var body: some View {
        WFWorkflowEditor(state: store)
            .onAppear { defineWorkflow() }
    }

    func defineWorkflow() {
        // Declarative node definitions
        let fileWatcher = WorkflowNode(
            type: .trigger,
            title: "File Watcher",
            position: CGPoint(x: 100, y: 150)
        )

        let parseCSV = WorkflowNode(
            type: .transform,
            title: "Parse CSV",
            position: CGPoint(x: 350, y: 150),
            configuration: NodeConfiguration(
                expression: "rows.map { $0.split(\",\") }"
            )
        )

        let validateSchema = WorkflowNode(
            type: .condition,
            title: "Filter Errors",
            position: CGPoint(x: 600, y: 150),
            configuration: NodeConfiguration(
                condition: "row.isValid"
            )
        )

        let exportJSON = WorkflowNode(
            type: .output,
            title: "Export JSON",
            position: CGPoint(x: 850, y: 100)
        )

        // Build the graph
        store.addNodes([
            fileWatcher,
            parseCSV,
            validateSchema,
            exportJSON
        ])

        store.connect(from: fileWatcher, to: parseCSV)
        store.connect(from: parseCSV, to: validateSchema)
        store.connect(
            from: validateSchema, port: "valid",
            to: exportJSON
        )
    }
}`,
  'App.swift': `import SwiftUI
import WFKit

@main
struct MyApp: App {
    @State private var canvas = CanvasState()

    var body: some Scene {
        WindowGroup {
            WFWorkflowEditor(state: canvas)
        }
    }
}`,
  'Agents.swift': `let agent = WorkflowNode(
    type: .llm,
    title: "Research Agent",
    position: CGPoint(x: 400, y: 200),
    configuration: NodeConfiguration(
        prompt: """
            Analyze the query and extract:
            - Key entities
            - Required data sources
            - Suggested actions

            Query: {{input}}
            """,
        model: "claude-sonnet-4-20250514",
        temperature: 0.3,
        maxTokens: 2048
    )
)`,
  'Custom.swift': `// Extend with your own node types
extension NodeType {
    static let webhook = NodeType(
        id: "webhook",
        icon: "network",
        color: Color(hex: "#00D4AA")
    )
}

let stripeWebhook = WorkflowNode(
    type: .webhook,
    title: "Stripe Events",
    outputs: [
        .output("payment.success"),
        .output("payment.failed"),
        .output("subscription.created")
    ]
)`
};

type FileName = keyof typeof SNIPPETS;

// Robust Tokenizer Regex for Swift
const TOKENIZER_REGEX = /(\/\/.*)|("""[\s\S]*?"""|"(?:[^"\\]|\\.)*")|(@\w+)|(\b(?:import|struct|var|let|func|return|some|extension|if|else|switch|case|default|public|private|init)\b)|(\b[A-Z]\w+\b)|(\b\w+:)/g;

const HighlightedCode = ({ code }: { code: string }) => {
  const elements: React.ReactNode[] = [];
  let lastIndex = 0;
  let match;

  // Reset regex state
  TOKENIZER_REGEX.lastIndex = 0;

  while ((match = TOKENIZER_REGEX.exec(code)) !== null) {
    const [fullMatch, comment, string, decorator, keyword, type, arg] = match;
    const index = match.index;

    // Push preceding plain text
    if (index > lastIndex) {
      elements.push(code.slice(lastIndex, index));
    }

    if (comment) {
      elements.push(<span key={index} className="text-zinc-500 italic">{comment}</span>);
    } else if (string) {
      elements.push(<span key={index} className="text-green-400">{string}</span>);
    } else if (decorator) {
      elements.push(<span key={index} className="text-pink-400">{decorator}</span>);
    } else if (keyword) {
      elements.push(<span key={index} className="text-purple-400">{keyword}</span>);
    } else if (type) {
      elements.push(<span key={index} className="text-yellow-200">{type}</span>);
    } else if (arg) {
      elements.push(<span key={index} className="text-blue-300">{arg}</span>);
    } else {
      elements.push(fullMatch);
    }

    lastIndex = TOKENIZER_REGEX.lastIndex;
  }

  // Push remaining text
  if (lastIndex < code.length) {
    elements.push(code.slice(lastIndex));
  }

  return <>{elements}</>;
};

interface CodeArchitectureProps {
  frameless?: boolean;
}

export const CodeArchitecture: React.FC<CodeArchitectureProps> = ({ frameless = false }) => {
  const [activeFile, setActiveFile] = useState<FileName>('Workflow.swift');
  const [copied, setCopied] = useState(false);

  const codeSnippet = SNIPPETS[activeFile];

  const copyToClipboard = () => {
    navigator.clipboard.writeText(codeSnippet);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const FileItem = ({ name, icon: Icon, color }: { name: FileName, icon: any, color: string }) => (
    <div 
      onClick={() => setActiveFile(name)}
      className={`flex items-center gap-2 p-2 rounded cursor-pointer transition-colors border ${activeFile === name ? 'bg-zinc-800/50 border-zinc-700 text-white' : 'border-transparent text-zinc-500 hover:text-zinc-300'}`}
    >
       <Icon size={12} className={color} />
       <span className="text-[10px] font-mono">{name}</span>
    </div>
  );

  return (
    <div className={`${frameless ? '' : 'border border-zinc-800'} bg-[#09090b] grid lg:grid-cols-5 relative group min-h-[600px] h-full`}>
      {!frameless && (
        <>
          <div className="absolute -top-1 -left-1 w-2 h-2 border-t border-l border-white"></div>
          <div className="absolute -top-1 -right-1 w-2 h-2 border-t border-r border-white"></div>
          <div className="absolute -bottom-1 -left-1 w-2 h-2 border-b border-l border-white"></div>
          <div className="absolute -bottom-1 -right-1 w-2 h-2 border-b border-r border-white"></div>
        </>
      )}

      {/* Sidebar / File Explorer */}
      <div className="lg:col-span-1 border-b lg:border-b-0 lg:border-r border-zinc-800 bg-[#0c0c0e] p-4 flex flex-col gap-6">
        <div className="flex items-center gap-2 text-white mb-2">
           <Terminal size={14} />
           <span className="text-xs font-bold uppercase tracking-wider">Explorer</span>
        </div>
        
        <div className="flex flex-col gap-1">
          <FileItem name="Workflow.swift" icon={FileCode} color="text-blue-400" />
          <FileItem name="App.swift" icon={Box} color="text-orange-400" />
          <FileItem name="Agents.swift" icon={Cpu} color="text-purple-400" />
          <FileItem name="Custom.swift" icon={Sliders} color="text-green-400" />
        </div>
        
        <div className="mt-auto border-t border-zinc-800 pt-4">
           <div className="text-[10px] text-zinc-600 uppercase tracking-widest font-bold mb-2">Build Status</div>
           <div className="flex items-center gap-2 text-green-500">
             <div className="w-1.5 h-1.5 rounded-full bg-current"></div>
             <span className="text-xs font-mono">Succeeded</span>
           </div>
        </div>
      </div>

      {/* Code Viewer */}
      <div className="lg:col-span-4 flex flex-col h-full bg-[#050505] relative">
        <div className="flex items-center justify-between px-4 py-3 border-b border-zinc-800 bg-zinc-900/20">
          <div className="flex items-center gap-2">
            <span className="text-[10px] text-zinc-500 font-mono">Sources / Workflows /</span>
            <span className="text-[10px] text-zinc-300 font-bold uppercase tracking-widest">{activeFile}</span>
          </div>
          <button onClick={copyToClipboard} className="text-zinc-500 hover:text-white transition-colors">
            {copied ? <Check size={14} /> : <Copy size={14} />}
          </button>
        </div>
        
        <div className="flex-1 overflow-auto p-6 custom-scrollbar">
          <pre className="font-mono text-xs md:text-sm leading-6 text-zinc-400">
            <code>
              {codeSnippet.split('\n').map((line, i) => (
                <div key={i} className="table-row">
                  <span className="table-cell text-zinc-800 select-none text-right pr-4 w-8">{i + 1}</span>
                  <span className="table-cell whitespace-pre-wrap break-all">
                    <HighlightedCode code={line} />
                  </span>
                </div>
              ))}
            </code>
          </pre>
        </div>
      </div>
    </div>
  );
};