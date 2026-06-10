import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "EduNoteAI Admin",
  description: "Yönetim Paneli ve Dashboard",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="tr" className="dark">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased min-h-screen bg-background flex flex-col md:flex-row`}
      >
        <Sidebar />
        <main className="flex-1 flex flex-col min-w-0 overflow-hidden">
          <Topnav />
          <div className="flex-1 overflow-auto p-4 md:p-8">
            {children}
          </div>
        </main>
      </body>
    </html>
  );
}

// ─── Simple Layout Components ─────────────────────────────────
import { LayoutDashboard, Users, Database, Settings, Sparkles, LogOut, Bell, Search } from "lucide-react";

function Sidebar() {
  return (
    <aside className="w-64 border-r border-border/40 bg-card/30 hidden md:flex flex-col h-screen backdrop-blur-md">
      <div className="p-6 flex items-center gap-3 border-b border-border/40">
        <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center shadow-[0_0_15px_rgba(var(--primary),0.5)]">
          <Sparkles className="text-primary-foreground w-5 h-5" />
        </div>
        <h1 className="font-bold text-xl tracking-tight">EduNote<span className="text-primary">AI</span></h1>
      </div>
      
      <div className="flex-1 overflow-auto py-6 px-4 flex flex-col gap-2">
        <NavItem icon={LayoutDashboard} label="Dashboard" active />
        <NavItem icon={Users} label="Kullanıcılar" />
        <NavItem icon={Database} label="Not Defterleri" />
        <NavItem icon={Sparkles} label="AI Metrikleri" badge="New" />
        <NavItem icon={Settings} label="Ayarlar" />
      </div>
      
      <div className="p-4 border-t border-border/40">
        <div className="flex items-center gap-3 p-2 rounded-lg hover:bg-muted/50 transition-colors cursor-pointer text-muted-foreground hover:text-foreground">
          <LogOut className="w-5 h-5" />
          <span className="font-medium text-sm">Çıkış Yap</span>
        </div>
      </div>
    </aside>
  );
}

function NavItem({ icon: Icon, label, active, badge }: { icon: any, label: string, active?: boolean, badge?: string }) {
  return (
    <div className={`flex items-center justify-between p-3 rounded-lg cursor-pointer transition-all ${active ? 'bg-primary/10 text-primary font-medium' : 'text-muted-foreground hover:text-foreground hover:bg-muted/50'}`}>
      <div className="flex items-center gap-3">
        <Icon className={`w-5 h-5 ${active ? 'text-primary' : ''}`} />
        <span>{label}</span>
      </div>
      {badge && (
        <span className="text-[10px] uppercase tracking-wider font-bold bg-primary text-primary-foreground px-2 py-0.5 rounded-full shadow-[0_0_10px_rgba(var(--primary),0.4)]">
          {badge}
        </span>
      )}
    </div>
  );
}

function Topnav() {
  return (
    <header className="h-16 glass flex items-center justify-between px-6 sticky top-0 z-10">
      <div className="md:hidden flex items-center gap-3">
        <Sparkles className="text-primary w-6 h-6" />
        <span className="font-bold text-lg">EduNoteAI</span>
      </div>
      
      <div className="hidden md:flex relative w-96">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input 
          type="text" 
          placeholder="Arama yapın..." 
          className="w-full bg-muted/50 border-none rounded-full py-2 pl-10 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-primary/50 transition-all placeholder:text-muted-foreground"
        />
      </div>
      
      <div className="flex items-center gap-4">
        <button className="relative p-2 rounded-full hover:bg-muted/50 transition-colors text-muted-foreground hover:text-foreground">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1 right-1 w-2 h-2 bg-primary rounded-full animate-pulse shadow-[0_0_8px_rgba(var(--primary),0.8)]"></span>
        </button>
        <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-primary to-purple-600 p-[2px]">
          <div className="w-full h-full rounded-full bg-card flex items-center justify-center overflow-hidden">
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Admin" alt="Admin" className="w-full h-full object-cover" />
          </div>
        </div>
      </div>
    </header>
  );
}
