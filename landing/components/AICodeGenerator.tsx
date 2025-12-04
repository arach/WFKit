import React, { useState } from 'react';
import { Terminal, Copy, Check, FileCode, Box } from 'lucide-react';

const SNIPPETS = {
  'App.swift': `import SwiftUI
import WFKit

@main
struct MyApp: App {
    @State private var canvas = CanvasState()

    var body: some Scene {
        WindowGroup {
            // Load workflow from TWF file
            WFWorkflowEditor(state: canvas)
                .onAppear {
                    if let url = Bundle.main.url(
                        forResource: "learning-capture",
                        withExtension: "twf.json"
                    ) {
                        canvas.load(from: url)
                    }
                }
        }
    }
}`,
  'key-insights.twf.json': `{
  "slug": "key-insights",
  "name": "Key Insights",
  "description": "Extract 3-5 key takeaways",
  "icon": "lightbulb",
  "color": "yellow",
  "isEnabled": true,
  "steps": [
    {
      "id": "extract-insights",
      "type": "LLM Generation",
      "config": {
        "llm": {
          "provider": "gemini",
          "modelId": "gemini-2.0-flash",
          "prompt": "Extract 3-5 key takeaways from:\\n{{TRANSCRIPT}}\\n\\nReturn JSON array: [\"Insight 1\", ...]",
          "temperature": 0.5,
          "maxTokens": 1024
        }
      }
    }
  ]
}`,
  'learning-capture.twf.json': `{
  "slug": "learning-capture",
  "name": "Learning Capture",
  "description": "Voice notes → Obsidian with auto-tags",
  "icon": "book.pages",
  "color": "indigo",
  "steps": [
    {
      "id": "extract-concepts",
      "type": "LLM Generation",
      "config": {
        "llm": {
          "costTier": "balanced",
          "prompt": "Extract concepts from:\\n{{TRANSCRIPT}}\\n\\nReturn: {mainTopic, concepts[], keyInsight, questions[]}",
          "temperature": 0.3
        }
      }
    },
    {
      "id": "parse-json",
      "type": "Transform Data",
      "config": {
        "transform": { "operation": "Extract JSON" }
      }
    },
    {
      "id": "format-note",
      "type": "LLM Generation",
      "config": {
        "llm": {
          "costTier": "budget",
          "prompt": "Format as Obsidian note with [[backlinks]]:\\n{{parse-json}}",
          "temperature": 0.3
        }
      }
    },
    {
      "id": "save-note",
      "type": "Save to File",
      "config": {
        "saveFile": {
          "filename": "{{DATE}}-{{parse-json.mainTopic}}.md",
          "directory": "@Obsidian/Learning",
          "content": "# {{parse-json.mainTopic}}\\n{{format-note}}"
        }
      }
    }
  ]
}`,
  'brain-dump.twf.json': `{
  "slug": "brain-dump-processor",
  "name": "Brain Dump Processor",
  "description": "Brainstorms → Ideas + Reminders + Notes",
  "icon": "brain.head.profile",
  "color": "purple",
  "steps": [
    {
      "id": "transcribe",
      "type": "Transcribe Audio",
      "config": { "transcribe": { "model": "openai_whisper-small" } }
    },
    {
      "id": "extract-ideas",
      "type": "LLM Generation",
      "config": {
        "llm": {
          "provider": "gemini",
          "prompt": "Extract ideas from:\\n{{transcribe}}\\n\\nReturn: {ideas: [{title, category}], nextActions[]}",
          "temperature": 0.5
        }
      }
    },
    {
      "id": "check-actions",
      "type": "Conditional Branch",
      "config": {
        "conditional": {
          "condition": "{{extract-ideas.nextActions.length}} > 0",
          "thenSteps": ["create-reminder"],
          "elseSteps": []
        }
      }
    },
    {
      "id": "create-reminder",
      "type": "Create Reminder",
      "config": {
        "appleReminders": {
          "title": "{{extract-ideas.nextActions[0]}}",
          "dueDate": "{{NOW+1d}}"
        }
      }
    },
    {
      "id": "expand-research",
      "type": "LLM Generation",
      "config": {
        "llm": {
          "provider": "openai",
          "modelId": "gpt-4o",
          "prompt": "Suggest related concepts and experiments for:\\n{{extract-ideas.ideas}}",
          "temperature": 0.7
        }
      }
    },
    {
      "id": "save-note",
      "type": "Save to File",
      "config": {
        "saveFile": {
          "filename": "{{DATE}}-{{TITLE}}.md",
          "directory": "@Obsidian/Ideas",
          "content": "# {{TITLE}}\\n{{expand-research}}"
        }
      }
    }
  ]
}`
};

type FileName = keyof typeof SNIPPETS;

// Robust Tokenizer Regex for Swift and JSON
const SWIFT_TOKENIZER_REGEX = /(\/\/.*)|("""[\s\S]*?"""|"(?:[^"\\]|\\.)*")|(@\w+)|(\b(?:import|struct|var|let|func|return|some|extension|if|else|switch|case|default|public|private|init)\b)|(\b[A-Z]\w+\b)|(\b\w+:)/g;
const JSON_TOKENIZER_REGEX = /("(?:[^"\\]|\\.)*"\s*:)|("(?:[^"\\]|\\.)*")|(\b(?:true|false|null)\b)|(\b-?\d+\.?\d*\b)/g;

const HighlightedSwiftCode = ({ code }: { code: string }) => {
  const elements: React.ReactNode[] = [];
  let lastIndex = 0;
  let match;

  SWIFT_TOKENIZER_REGEX.lastIndex = 0;

  while ((match = SWIFT_TOKENIZER_REGEX.exec(code)) !== null) {
    const [fullMatch, comment, string, decorator, keyword, type, arg] = match;
    const index = match.index;

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

    lastIndex = SWIFT_TOKENIZER_REGEX.lastIndex;
  }

  if (lastIndex < code.length) {
    elements.push(code.slice(lastIndex));
  }

  return <>{elements}</>;
};

const HighlightedJsonCode = ({ code }: { code: string }) => {
  const elements: React.ReactNode[] = [];
  let lastIndex = 0;
  let match;

  JSON_TOKENIZER_REGEX.lastIndex = 0;

  while ((match = JSON_TOKENIZER_REGEX.exec(code)) !== null) {
    const [fullMatch, key, string, bool, num] = match;
    const index = match.index;

    if (index > lastIndex) {
      elements.push(code.slice(lastIndex, index));
    }

    if (key) {
      elements.push(<span key={index} className="text-blue-300">{key}</span>);
    } else if (string) {
      elements.push(<span key={index} className="text-green-400">{string}</span>);
    } else if (bool) {
      elements.push(<span key={index} className="text-purple-400">{bool}</span>);
    } else if (num) {
      elements.push(<span key={index} className="text-yellow-300">{num}</span>);
    } else {
      elements.push(fullMatch);
    }

    lastIndex = JSON_TOKENIZER_REGEX.lastIndex;
  }

  if (lastIndex < code.length) {
    elements.push(code.slice(lastIndex));
  }

  return <>{elements}</>;
};

const HighlightedCode = ({ code, isJson }: { code: string; isJson: boolean }) => {
  return isJson ? <HighlightedJsonCode code={code} /> : <HighlightedSwiftCode code={code} />;
};

interface CodeArchitectureProps {
  frameless?: boolean;
}

export const CodeArchitecture: React.FC<CodeArchitectureProps> = ({ frameless = false }) => {
  const [activeFile, setActiveFile] = useState<FileName>('App.swift');
  const isJson = activeFile.endsWith('.json');
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
          <FileItem name="App.swift" icon={Box} color="text-orange-400" />
          <FileItem name="key-insights.twf.json" icon={FileCode} color="text-yellow-400" />
          <FileItem name="learning-capture.twf.json" icon={FileCode} color="text-indigo-400" />
          <FileItem name="brain-dump.twf.json" icon={FileCode} color="text-purple-400" />
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
                    <HighlightedCode code={line} isJson={isJson} />
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