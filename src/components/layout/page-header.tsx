import { ReactNode } from "react";
import { ArrowLeft } from "lucide-react";
import { useNavigate } from "react-router-dom";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  children?: ReactNode;
  className?: string;
  showBackButton?: boolean;
  backTo?: string;
  showLogo?: boolean;
}

export function PageHeader({ 
  title, 
  subtitle, 
  children, 
  className,
  showBackButton = false,
  backTo = "..",
  showLogo = false
}: PageHeaderProps) {
  const navigate = useNavigate();

  const handleBack = () => {
    if (backTo === "..") {
      navigate(-1); // Go back in history
    } else {
      navigate(backTo);
    }
  };

  return (
    <header className={`mb-6 ${className || ""}`}>
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-3 mb-2">
            {showBackButton && (
              <button
                onClick={handleBack}
                className="flex items-center justify-center w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 transition-colors flex-shrink-0"
                aria-label="Go back"
              >
                <ArrowLeft className="w-4 h-4 text-gray-600" />
              </button>
            )}
            {showLogo && (
              <img 
                src="/logo-streakzilla-bh.png" 
                alt="Streakzilla" 
                className="h-9 w-auto"
              />
            )}
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold text-foreground mb-1 leading-tight">{title}</h1>
          {subtitle && (
            <p className="text-muted-foreground text-sm sm:text-base leading-relaxed">{subtitle}</p>
          )}
        </div>
        {children && (
          <div className="flex items-start gap-2 flex-shrink-0">
            {children}
          </div>
        )}
      </div>
    </header>
  );
}