"use client";

import { motion } from "framer-motion";
import { Users, FileText, BrainCircuit, Activity, TrendingUp, Sparkles } from "lucide-react";
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer,
  AreaChart, Area
} from "recharts";

// Mock Data
const userGrowthData = [
  { name: 'Oca', users: 4000, active: 2400 },
  { name: 'Şub', users: 5000, active: 3200 },
  { name: 'Mar', users: 6500, active: 4800 },
  { name: 'Nis', users: 8200, active: 6100 },
  { name: 'May', users: 11000, active: 8500 },
  { name: 'Haz', users: 15400, active: 12000 },
];

const aiUsageData = [
  { name: 'Pzt', tokens: 1.2 },
  { name: 'Sal', tokens: 2.1 },
  { name: 'Çar', tokens: 1.8 },
  { name: 'Per', tokens: 3.4 },
  { name: 'Cum', tokens: 4.2 },
  { name: 'Cmt', tokens: 5.8 },
  { name: 'Paz', tokens: 4.9 },
];

const recentActivity = [
  { user: "Ahmet Yılmaz", action: "Yeni bir not defteri oluşturdu", time: "2 dk önce", avatar: "A" },
  { user: "Zeynep Kaya", action: "AI Özetleme kullandı", time: "15 dk önce", avatar: "Z" },
  { user: "Can Öz", action: "Pro plana geçti", time: "1 saat önce", avatar: "C", isPro: true },
  { user: "Ayşe Demir", action: "PDF yükledi (Fizik Notları)", time: "3 saat önce", avatar: "A" },
];

export default function DashboardPage() {
  return (
    <div className="space-y-8 pb-10">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">Genel Bakış</h2>
          <p className="text-muted-foreground mt-1">Sisteminizin bugünkü durumu ve özet istatistikler.</p>
        </div>
        <div className="flex items-center gap-3">
          <button className="px-4 py-2 rounded-lg bg-card border border-border text-sm font-medium hover:bg-muted/50 transition-colors">
            Rapor İndir
          </button>
          <button className="px-4 py-2 rounded-lg bg-primary text-primary-foreground text-sm font-medium shadow-[0_0_15px_rgba(var(--primary),0.4)] hover:opacity-90 transition-opacity flex items-center gap-2">
            <Sparkles className="w-4 h-4" />
            AI Raporu
          </button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard 
          title="Toplam Kullanıcı" 
          value="15,402" 
          trend="+12.5%" 
          isPositive={true}
          icon={Users}
          delay={0.1}
        />
        <StatCard 
          title="Aktif Not Defteri" 
          value="48,291" 
          trend="+8.2%" 
          isPositive={true}
          icon={FileText}
          delay={0.2}
        />
        <StatCard 
          title="Günlük AI İsteği" 
          value="12.4k" 
          trend="+24.8%" 
          isPositive={true}
          icon={BrainCircuit}
          delay={0.3}
          highlight
        />
        <StatCard 
          title="Sistem Yükü" 
          value="34%" 
          trend="-2.4%" 
          isPositive={true}
          icon={Activity}
          delay={0.4}
        />
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Main Chart */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="lg:col-span-2 p-6 rounded-xl bg-card border border-border shadow-sm flex flex-col"
        >
          <div className="mb-6">
            <h3 className="font-semibold text-lg">Kullanıcı Büyümesi</h3>
            <p className="text-sm text-muted-foreground">Son 6 aylık kayıtlı ve aktif kullanıcı trendi.</p>
          </div>
          <div className="h-[300px] w-full mt-auto">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={userGrowthData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.3}/>
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: 'var(--muted-foreground)', fontSize: 12}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: 'var(--muted-foreground)', fontSize: 12}} />
                <RechartsTooltip 
                  contentStyle={{ backgroundColor: 'var(--card)', borderColor: 'var(--border)', borderRadius: '8px' }}
                  itemStyle={{ color: 'var(--foreground)' }}
                />
                <Area type="monotone" dataKey="users" stroke="var(--primary)" strokeWidth={3} fillOpacity={1} fill="url(#colorUsers)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </motion.div>

        {/* Secondary Chart */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
          className="p-6 rounded-xl bg-card border border-border shadow-sm flex flex-col relative overflow-hidden"
        >
          {/* Subtle background glow */}
          <div className="absolute -top-24 -right-24 w-48 h-48 bg-primary/20 rounded-full blur-3xl pointer-events-none"></div>

          <div className="mb-6 relative z-10">
            <div className="flex items-center gap-2 mb-1">
              <BrainCircuit className="w-5 h-5 text-primary" />
              <h3 className="font-semibold text-lg">AI Token Tüketimi</h3>
            </div>
            <p className="text-sm text-muted-foreground">Haftalık milyon token bazında (Gemini API).</p>
          </div>
          <div className="h-[250px] w-full mt-auto relative z-10">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={aiUsageData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--border)" opacity={0.5} />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: 'var(--muted-foreground)', fontSize: 12}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: 'var(--muted-foreground)', fontSize: 12}} />
                <RechartsTooltip 
                  contentStyle={{ backgroundColor: 'var(--card)', borderColor: 'var(--border)', borderRadius: '8px' }}
                  itemStyle={{ color: 'var(--foreground)' }}
                />
                <Line type="monotone" dataKey="tokens" stroke="var(--primary)" strokeWidth={3} dot={{r: 4, fill: 'var(--primary)', strokeWidth: 2, stroke: 'var(--background)'}} activeDot={{r: 6, strokeWidth: 0, fill: 'var(--primary)'}} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </motion.div>
      </div>

      {/* Bottom Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Recent Activity */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.7 }}
          className="lg:col-span-2 p-6 rounded-xl bg-card border border-border shadow-sm"
        >
          <div className="flex items-center justify-between mb-6">
            <h3 className="font-semibold text-lg">Son Aktiviteler</h3>
            <button className="text-sm text-primary hover:underline">Tümünü Gör</button>
          </div>
          <div className="space-y-4">
            {recentActivity.map((item, i) => (
              <div key={i} className="flex items-center justify-between p-3 hover:bg-muted/30 rounded-lg transition-colors group cursor-pointer border border-transparent hover:border-border/50">
                <div className="flex items-center gap-4">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-primary/20 to-primary/5 flex items-center justify-center border border-primary/20 text-primary font-bold shadow-sm">
                    {item.avatar}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-sm">{item.user}</p>
                      {item.isPro && (
                        <span className="text-[10px] uppercase font-bold bg-gradient-to-r from-amber-500 to-orange-500 text-white px-1.5 py-0.5 rounded shadow-[0_0_8px_rgba(245,158,11,0.5)]">PRO</span>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">{item.action}</p>
                  </div>
                </div>
                <div className="text-xs text-muted-foreground">{item.time}</div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Quick Tips / Upgrade */}
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.8 }}
          className="p-6 rounded-xl border border-primary/30 shadow-[0_0_30px_rgba(var(--primary),0.1)] relative overflow-hidden flex flex-col justify-between group"
          style={{
            background: 'linear-gradient(135deg, var(--card) 0%, rgba(var(--primary), 0.05) 100%)'
          }}
        >
          <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 rounded-bl-full blur-2xl group-hover:bg-primary/30 transition-colors duration-500"></div>
          
          <div className="relative z-10">
            <div className="w-12 h-12 rounded-xl bg-primary/20 flex items-center justify-center mb-4 border border-primary/30">
              <Sparkles className="text-primary w-6 h-6" />
            </div>
            <h3 className="font-bold text-xl mb-2">Gemini Pro'ya Yükselt</h3>
            <p className="text-sm text-muted-foreground mb-6">
              Sisteminiz şu an gemini-1.5-flash kullanıyor. Daha karmaşık PDF analizleri için Pro modele geçiş yapabilirsiniz.
            </p>
          </div>
          
          <button className="relative z-10 w-full py-3 rounded-lg bg-primary text-primary-foreground font-semibold shadow-[0_0_15px_rgba(var(--primary),0.3)] hover:shadow-[0_0_25px_rgba(var(--primary),0.5)] transition-shadow">
            Ayarları Yapılandır
          </button>
        </motion.div>
      </div>

    </div>
  );
}

function StatCard({ title, value, trend, isPositive, icon: Icon, delay, highlight }: any) {
  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay }}
      className={`p-6 rounded-xl border relative overflow-hidden ${
        highlight 
          ? 'bg-card border-primary/40 shadow-[0_0_20px_rgba(var(--primary),0.15)]' 
          : 'bg-card border-border shadow-sm'
      }`}
    >
      {highlight && (
        <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-primary to-purple-500"></div>
      )}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-sm font-medium text-muted-foreground">{title}</h3>
        <div className={`p-2 rounded-lg ${highlight ? 'bg-primary/20 text-primary' : 'bg-muted text-muted-foreground'}`}>
          <Icon className="w-4 h-4" />
        </div>
      </div>
      <div className="flex items-baseline gap-2">
        <h2 className={`text-3xl font-bold tracking-tight ${highlight ? 'text-primary' : ''}`}>{value}</h2>
      </div>
      <div className="mt-2 flex items-center text-xs">
        <TrendingUp className={`w-3 h-3 mr-1 ${isPositive ? 'text-emerald-500' : 'text-red-500'}`} />
        <span className={isPositive ? 'text-emerald-500 font-medium' : 'text-red-500 font-medium'}>
          {trend}
        </span>
        <span className="text-muted-foreground ml-1">geçen haftaya göre</span>
      </div>
    </motion.div>
  );
}
