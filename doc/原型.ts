import React, { useState, useEffect } from 'react';

import { Wind, HeartPulse, ArrowRight, X, ChevronLeft, Activity, Leaf, CheckCircle2, CircleDashed, ShieldCheck, Archive, BookOpen, ChevronRight } from 'lucide-react';

  

const globalStyles = `

  @keyframes breathe {

    0%, 100% { transform: scale(1); opacity: 0.8; }

    50% { transform: scale(1.08); opacity: 1; }

  }

  @keyframes floatUp {

    from { opacity: 0; transform: translateY(16px); }

    to { opacity: 1; transform: translateY(0); }

  }

  @keyframes fadeIn {

    from { opacity: 0; }

    to { opacity: 1; }

  }

  @keyframes slideInRight {

    from { opacity: 0; transform: translateX(20px); }

    to { opacity: 1; transform: translateX(0); }

  }

  .animate-breathe {

    animation: breathe 4s ease-in-out infinite;

  }

  .animate-float {

    animation: floatUp 0.6s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;

  }

  .animate-fade {

    animation: fadeIn 0.4s ease-out forwards;

  }

  .animate-slide-right {

    animation: slideInRight 0.4s cubic-bezier(0.2, 0.8, 0.2, 1) forwards;

  }

  /* Hide scrollbar */

  ::-webkit-scrollbar {

    width: 0px;

    background: transparent;

  }

`;

  

const Button = ({ children, onClick, variant = 'default', className = '', disabled = false }) => {

  const baseStyle = "w-full py-4 px-6 rounded-2xl font-medium transition-all duration-300 flex items-center justify-center gap-2 active:scale-[0.98]";

  const variants = {

    default: "bg-[#819B8E] text-white shadow-sm hover:bg-[#728A7D]", // 鼠尾草绿

    ghost: "bg-transparent text-[#8E8E93] hover:bg-black/5",

    surface: "bg-white text-[#2D2D2D] shadow-sm border border-[#E5E5EA]",

    deviation: "bg-[#C2A878] text-white", // 沙土黄

    dark: "bg-[#2C2C2E] text-[#E5E5EA] border border-[#3A3A3C] hover:bg-[#3A3A3C]" // 夜间/急救模式

  };

  

  return (

    <button

      onClick={onClick}

      disabled={disabled}

      className={`${baseStyle} ${variants[variant]} ${disabled ? 'opacity-40 cursor-not-allowed' : ''} ${className}`}

    >

      {children}

    </button>

  );

};

  

const Card = ({ children, className = '', onClick }) => (

  <div

    onClick={onClick}

    className={`bg-white rounded-[2rem] p-6 shadow-[0_2px_15px_rgba(0,0,0,0.03)] border border-[#F0F0F0] ${onClick ? 'cursor-pointer active:scale-[0.98] transition-transform' : ''} ${className}`}

  >

    {children}

  </div>

);

  

const OnboardingView = ({ onNavigate }) => {

  return (

    <div className="h-full bg-[#1C1C1E] text-[#E5E5EA] flex flex-col justify-between p-8 animate-fade">

      <div className="pt-20 animate-float" style={{ animationDelay: '0.1s' }}>

        <Wind size={48} className="text-[#819B8E] mb-8 animate-breathe" />

        <h1 className="text-3xl font-semibold tracking-tight leading-tight mb-4">

          欢迎来到<br />认知真空区。

        </h1>

        <p className="text-[#8E8E93] text-base leading-relaxed">

          在这里，没有打卡连签，没有进度压迫。<br /><br />

          只有绝对的安全、无评判的自省。<br />

          授权开启极简模式，我们将为你屏蔽外界噪音。

        </p>

      </div>

  

      <div className="pb-8 animate-float" style={{ animationDelay: '0.3s' }}>

        <div className="bg-[#2C2C2E] rounded-2xl p-4 mb-8 flex items-start gap-4 border border-[#3A3A3C]">

          <ShieldCheck className="text-[#819B8E] shrink-0 mt-0.5" size={20} />

          <div className="text-sm text-[#A1A1A6] leading-relaxed">

            <strong className="text-[#E5E5EA] font-medium">一键降噪已就绪</strong><br/>

            接下来的流程，请确保自己处于独处环境，切断一切社交信息流。

          </div>

        </div>

        <Button onClick={() => onNavigate('wizard')} variant="default" className="!bg-[#E5E5EA] !text-[#1C1C1E] hover:!bg-white">

          开启 24h 重构向导 <ArrowRight size={18} />

        </Button>

      </div>

    </div>

  );

};

  

const HomeView = ({ onNavigate }) => {

  return (

    <div className="h-full flex flex-col justify-between p-6 pt-12 animate-fade relative bg-[#F7F7F5]">

      {/* 顶部导航 */}

      <div className="flex justify-between items-center text-[#8E8E93] px-2 z-10">

        <button onClick={() => onNavigate('onboarding')} className="p-2 hover:bg-black/5 rounded-full transition-colors"><Wind size={20} /></button>

        <span className="text-xs tracking-widest uppercase font-medium text-[#2D2D2D]/60">ResetSelf</span>

        <button onClick={() => onNavigate('insights')} className="p-2 hover:bg-black/5 rounded-full transition-colors relative">

          <Archive size={20} />

          {/* 小红点替代物：柔和的莫兰迪绿点 */}

          <span className="absolute top-2 right-2 w-2 h-2 bg-[#819B8E] rounded-full border-2 border-[#F7F7F5]"></span>

        </button>

      </div>

  

      {/* 核心身份区域 */}

      <div className="flex-1 flex flex-col justify-center items-center mt-[-8vh] animate-float">

        <div className="px-4 py-1.5 rounded-full bg-[#E8F0EC] text-[#819B8E] text-xs font-medium tracking-widest mb-6">

          当前核心身份

        </div>

        <h1 className="text-3xl font-semibold text-[#2D2D2D] tracking-tight leading-snug text-center mb-10">

          "我是一个<br/>看重长远价值的人"

        </h1>

  

        <Card className="w-full max-w-sm flex items-center justify-between shadow-sm">

          <div className="flex flex-col">

            <span className="text-xs text-[#8E8E93] mb-1.5 flex items-center gap-1">

              <BookOpen size={12} /> 明日极简动作

            </span>

            <span className="text-[#2D2D2D] font-medium">清理办公桌面 5 分钟</span>

          </div>

          <div className="h-10 w-10 rounded-full bg-[#F7F7F5] flex items-center justify-center text-[#8E8E93] border border-[#E5E5EA]">

            <CheckCircle2 size={20} />

          </div>

        </Card>

      </div>

  

      {/* 底部交互区 */}

      <div className="pb-8 animate-float" style={{ animationDelay: '0.2s' }}>

        <Button onClick={() => onNavigate('checkin')} className="mb-4">

          进行今日校验 <ArrowRight size={18} />

        </Button>

        <div className="text-center">

          <span className="text-xs text-[#8E8E93]">无需自责，系统只做状态校准</span>

        </div>

      </div>

  

      {/* 悬浮 SOS 急救按钮 */}

      <button

        onClick={() => onNavigate('sos')}

        className="absolute bottom-32 right-6 h-14 w-14 bg-white shadow-[0_4px_20px_rgba(0,0,0,0.08)] rounded-full flex items-center justify-center text-[#819B8E] animate-breathe border border-[#F0F0F0]"

      >

        <HeartPulse size={24} />

      </button>

    </div>

  );

};

  

const WIZARD_STEPS = [

  { id: 'anti', phase: '上午 90min', title: '反愿景', desc: '如果保持现状 5 年不改变，\n最让你感到恐惧的画面是什么？', placeholder: '写下最真实的恶果，不要美化...' },

  { id: 'fear', phase: '上午 90min', title: '底层恐惧', desc: '剥离外界期待后，\n你内心深处到底在逃避什么？', placeholder: '怕失败、怕他人的评价、还是怕承担责任...' },

  { id: 'belief', phase: '夜晚 120min', title: '限制性信念', desc: '提炼出阻碍你的，\n最深层的一个自我否定信念。', placeholder: '例如：我总觉得自己不配得到好结果...' },

  { id: 'identity', phase: '夜晚 120min', title: '新身份叙事', desc: '写下你的新身份。\n不要结果指标，只要状态叙述。', placeholder: '我是一个______的人' },

  { id: 'action', phase: '夜晚 120min', title: '极简行动', desc: '为了印证这个新身份，\n明天你可以立刻做的零门槛动作是？', placeholder: '例如：早起喝一杯温水' },

];

  

const WizardView = ({ onNavigate }) => {

  const [currentStepIndex, setCurrentStepIndex] = useState(0);

  const [formData, setFormData] = useState({});

  const [isFocused, setIsFocused] = useState(false);

  

  const step = WIZARD_STEPS[currentStepIndex];

  const isLastStep = currentStepIndex === WIZARD_STEPS.length - 1;

  const currentText = formData[step.id] || '';

  

  const handleNext = () => {

    if (isLastStep) {

      onNavigate('home');

    } else {

      setCurrentStepIndex(prev => prev + 1);

      setIsFocused(false);

    }

  };

  

  return (

    <div key={step.id} className="h-full bg-[#F7F7F5] flex flex-col p-6 relative animate-slide-right transition-colors duration-500">

      {/* 顶部导航与进度 */}

      <div className={`flex items-center justify-between mt-6 transition-opacity duration-500 ${isFocused ? 'opacity-0' : 'opacity-100'}`}>

        <button

          onClick={() => currentStepIndex > 0 ? setCurrentStepIndex(p => p - 1) : onNavigate('onboarding')}

          className="p-2 text-[#8E8E93]"

        >

          <ChevronLeft size={24} />

        </button>

        <div className="flex flex-col items-center">

          <span className="text-[10px] text-[#8E8E93] uppercase tracking-widest mb-1">{step.phase}</span>

          <div className="flex gap-1.5">

            {WIZARD_STEPS.map((s, i) => (

              <div key={s.id} className={`h-1 rounded-full transition-all duration-300 ${i === currentStepIndex ? 'w-4 bg-[#819B8E]' : i < currentStepIndex ? 'w-2 bg-[#819B8E]/40' : 'w-2 bg-[#E5E5EA]'}`} />

            ))}

          </div>

        </div>

        <button onClick={() => onNavigate('home')} className="p-2 text-[#8E8E93]/50 text-xs">跳过</button>

      </div>

  

      {/* 核心问答区 */}

      <div className={`flex-1 flex flex-col justify-center max-w-sm mx-auto w-full transition-transform duration-500 ${isFocused ? '-translate-y-12' : ''}`}>

        <span className="text-xs text-[#819B8E] font-medium mb-3">{step.title}</span>

        <h2 className={`text-xl font-medium text-[#2D2D2D] mb-6 leading-relaxed whitespace-pre-line transition-opacity duration-500 ${isFocused ? 'opacity-40' : 'opacity-100'}`}>

          {step.desc}

        </h2>

        <div className="relative mt-2">

          <textarea

            value={currentText}

            onChange={(e) => setFormData({ ...formData, [step.id]: e.target.value })}

            onFocus={() => setIsFocused(true)}

            onBlur={() => setIsFocused(false)}

            placeholder={step.placeholder}

            className="w-full bg-transparent text-lg text-[#2D2D2D] placeholder-[#8E8E93]/40 outline-none resize-none min-h-[120px] leading-relaxed"

            autoFocus

          />

          <div className={`absolute bottom-0 left-0 h-[1px] bg-[#819B8E] transition-all duration-500 ${isFocused ? 'w-full' : 'w-0'}`} />

          <div className="absolute bottom-0 left-0 w-full h-[1px] bg-[#E5E5EA] -z-10" />

        </div>

  

        <div className="mt-6 min-h-[40px]">

          {currentText.length > 0 && currentText.length < 5 && (

            <p className="text-xs text-[#8E8E93] animate-fade flex items-center gap-1">

              <Leaf size={12} className="text-[#819B8E]" /> 再写点真实的细节，对自己更有帮助哦

            </p>

          )}

        </div>

      </div>

  

      {/* 底部操作区 */}

      <div className={`pb-8 transition-opacity duration-500 ${isFocused ? 'opacity-0' : 'opacity-100'}`}>

        <Button

          onClick={handleNext}

          disabled={currentText.length < 2}

          className="shadow-sm"

        >

          {isLastStep ? '完成重构，返回主页' : '保存并进入下一步'} <ArrowRight size={18} />

        </Button>

      </div>

    </div>

  );

};

  

const DailyCheckView = ({ onNavigate }) => {

  const [step, setStep] = useState('select');

  

  const handleSelect = (type) => {

    setStep('done');

    setTimeout(() => onNavigate('home'), 2200);

  };

  

  return (

    <div className="h-full bg-[#F7F7F5] flex flex-col p-6 relative animate-float">

      <button onClick={() => onNavigate('home')} className="absolute top-12 right-6 p-2 text-[#8E8E93]">

        <X size={24} />

      </button>

  

      {step === 'select' ? (

        <div className="flex-1 flex flex-col justify-center animate-fade">

          <Leaf className="text-[#819B8E] mb-6" size={32} />

          <h2 className="text-2xl font-medium text-[#2D2D2D] mb-3 leading-snug">今天的行为，<br/>匹配你的新身份吗？</h2>

          <p className="text-[#8E8E93] text-sm mb-10">无需自责，系统只做数据采样</p>

  

          <div className="space-y-4">

            <Button variant="surface" onClick={() => handleSelect('match')} className="justify-start py-5 font-normal">

              <div className="w-2 h-2 rounded-full bg-[#819B8E] mr-2" /> 完全匹配，状态很好

            </Button>

            <Button variant="surface" onClick={() => handleSelect('partial')} className="justify-start py-5 font-normal">

              <div className="w-2 h-2 rounded-full bg-[#C2A878] mr-2" /> 部分偏离，被旧习惯拉扯

            </Button>

            <Button variant="surface" onClick={() => handleSelect('full')} className="justify-start py-5 font-normal text-[#8E8E93]">

              <div className="w-2 h-2 rounded-full bg-[#E5E5EA] mr-2" /> 完全偏离，只记作偏差数据

            </Button>

          </div>

        </div>

      ) : (

        <div className="flex-1 flex flex-col justify-center items-center text-center animate-fade">

          <div className="w-16 h-16 rounded-full bg-[#E8F0EC] flex items-center justify-center text-[#819B8E] mb-6 animate-breathe">

            <CheckCircle2 size={32} />

          </div>

          <h2 className="text-xl font-medium text-[#2D2D2D] mb-2">已收录至惯性样本库</h2>

          <p className="text-[#8E8E93] text-sm leading-relaxed">每一次记录，都在让新的自我更清晰。<br/>辛苦了，明天见。</p>

        </div>

      )}

    </div>

  );

};

  

const InsightsView = ({ onNavigate }) => {

  return (

    <div className="h-full bg-[#F7F7F5] flex flex-col p-6 pt-12 animate-slide-right relative">

      <div className="flex items-center justify-between mb-8 px-2">

        <button onClick={() => onNavigate('home')} className="p-2 -ml-2 text-[#8E8E93] hover:bg-black/5 rounded-full">

          <ChevronLeft size={24} />

        </button>

        <span className="text-sm font-medium text-[#2D2D2D]">惯性样本库</span>

        <div className="w-8" />

      </div>

  

      <div className="flex-1 overflow-y-auto pb-10 hide-scrollbar">

        <p className="text-xs text-[#8E8E93] mb-6 px-2 leading-relaxed">

          偏差=迭代数据，偏差≠失败。<br/>这里记录了你被旧惯性拉扯的时刻。

        </p>

  

        <div className="space-y-4">

          <Card className="!p-5">

            <div className="flex justify-between items-start mb-3">

              <span className="text-xs font-medium text-[#C2A878] bg-[#F9F5EC] px-2 py-1 rounded-md">部分偏离</span>

              <span className="text-xs text-[#8E8E93]">昨天 21:00</span>

            </div>

            <p className="text-sm text-[#2D2D2D] leading-relaxed">

              因“觉得目标太大”感到焦虑，触发了逃避机制。

            </p>

          </Card>

  

          <Card className="!p-5 opacity-70">

            <div className="flex justify-between items-start mb-3">

              <span className="text-xs font-medium text-[#8E8E93] bg-[#F0F0F0] px-2 py-1 rounded-md">完全偏离</span>

              <span className="text-xs text-[#8E8E93]">周二 14:30</span>

            </div>

            <p className="text-sm text-[#2D2D2D] leading-relaxed">

              (系统自动采集) 潜意识感到了害怕，记录一次旧惯性反弹。

            </p>

          </Card>

          <div className="py-8 text-center text-xs text-[#8E8E93]/60">

            只展示最近 7 天的样本数据

          </div>

        </div>

      </div>

    </div>

  );

};

  

const SOSView = ({ onNavigate }) => {

  return (

    <div className="h-full bg-[#1C1C1E] text-[#E5E5EA] flex flex-col p-8 animate-fade relative">

      <button onClick={() => onNavigate('home')} className="absolute top-12 left-6 p-2 text-[#8E8E93]">

        <X size={24} />

      </button>

  

      <div className="flex-1 flex flex-col justify-center items-center text-center max-w-sm mx-auto w-full">

        <div className="mb-10 animate-breathe opacity-50">

          <HeartPulse size={48} className="text-[#819B8E]" />

        </div>

        <h2 className="text-2xl font-medium mb-4 leading-relaxed animate-float" style={{ animationDelay: '0.1s' }}>

          这不是你的错，<br/>是旧惯性的防御。

        </h2>

        <p className="text-[#8E8E93] text-sm mb-12 leading-relaxed animate-float" style={{ animationDelay: '0.3s' }}>

          你正试图改变，潜意识感到了害怕。<br/>深呼吸，告诉系统刚才发生了什么？

        </p>

  

        <div className="w-full space-y-3 animate-float" style={{ animationDelay: '0.5s' }}>

          <Button variant="dark" onClick={() => onNavigate('home')} className="justify-between px-5 font-normal text-sm">

            我感到焦虑，想逃避 <ChevronRight size={16} className="text-[#8E8E93]"/>

          </Button>

          <Button variant="dark" onClick={() => onNavigate('home')} className="justify-between px-5 font-normal text-sm">

            对庞大的目标感到畏惧 <ChevronRight size={16} className="text-[#8E8E93]"/>

          </Button>

          <div className="pt-6">

            <button onClick={() => onNavigate('wizard')} className="text-xs text-[#819B8E] hover:text-white transition-colors underline underline-offset-4 decoration-[#819B8E]/30">

              认为方向错了？重新进入 24h 重构

            </button>

          </div>

        </div>

      </div>

    </div>

  );

};

  

const App = () => {

  // 默认启动页设置为 onboarding 体验完整闭环

  const [currentView, setCurrentView] = useState('onboarding');

  

  useEffect(() => {

    const styleSheet = document.createElement("style");

    styleSheet.innerText = globalStyles;

    document.head.appendChild(styleSheet);

    return () => document.head.removeChild(styleSheet);

  }, []);

  

  // 外层包裹模拟移动端视口

  return (

    <div className="w-full h-screen bg-[#E5E5EA] flex items-center justify-center font-sans overflow-hidden">

      <div className="w-full h-full sm:h-[844px] sm:w-[390px] bg-[#F7F7F5] sm:rounded-[3rem] sm:shadow-[0_20px_60px_rgba(0,0,0,0.1)] relative overflow-hidden flex flex-col border-[6px] border-white/50">

        {currentView === 'onboarding' && <OnboardingView onNavigate={setCurrentView} />}

        {currentView === 'home' && <HomeView onNavigate={setCurrentView} />}

        {currentView === 'wizard' && <WizardView onNavigate={setCurrentView} />}

        {currentView === 'checkin' && <DailyCheckView onNavigate={setCurrentView} />}

        {currentView === 'insights' && <InsightsView onNavigate={setCurrentView} />}

        {currentView === 'sos' && <SOSView onNavigate={setCurrentView} />}

      </div>

    </div>

  );

};

  

export default App;