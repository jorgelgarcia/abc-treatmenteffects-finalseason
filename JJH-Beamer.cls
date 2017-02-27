% Custom class for JJH Beamer style and private notes
% Created by Jake Whitaker
% Do not edit unless you know what you are doing

\ProvidesClass{JJH-Beamer}[2013/08/30 JJH Beamer Custom Template]

%------------- Options ----------------------------------------------------------------------------

% new if conditionals for the options
\newif\if@staticDisplay
\newif\if@dynamicDisplay
\newif\if@handoutMode
\newif\if@articleMode
\newif\if@hceoMode
\newif\if@hceoLogoMode

\@dynamicDisplaytrue %setting dynamic as default in case there are no options given

% Declaring the options

\DeclareOption{static}{
    \@dynamicDisplayfalse
    \@staticDisplaytrue
}

\DeclareOption{dynamic}{
    \@dynamicDisplaytrue
}

% leaving handout as an option as it was used before "print"
\DeclareOption{handout}{
    \@dynamicDisplayfalse
    \@handoutModetrue
}

\DeclareOption{print}{
    \@dynamicDisplayfalse
    \@handoutModetrue
}

\DeclareOption{notes}{
    \@dynamicDisplayfalse
    \@articleModetrue
}

% HCEO theme, used in addition to the main 4 options
\DeclareOption{HCEO}{
    \@hceoModetrue
}

% UChicago Logo swapped with HCEO logo
\DeclareOption{HCEOLogo}{
    \@hceoLogoModetrue
}

% Warning for undeclared options
\DeclareOption*{
  \ClassWarning{JJH-Beamer}{Unknown option '\CurrentOption'}
  \PassOptionsToClass{\CurrentOption}{beamer}
  \PassOptionsToClass{\CurrentOption}{article}
}


\ProcessOptions\relax

%-----end of declaring options------------------------------------


% loading classes/ options based on options using if statements

\if@staticDisplay
    \LoadClass[12pt,compress,handout,ignorenonframetext]{beamer}
\fi

\if@dynamicDisplay
    \LoadClass[12pt,compress,ignorenonframetext]{beamer}
\fi

\if@handoutMode
    \LoadClass[12pt,compress,handout,ignorenonframetext]{beamer}
\fi


\if@articleMode
    \LoadClass[12pt]{article}
    \RequirePackage{beamerarticle}
\fi

%% -------------- Packages ------------------------------------------------------------------------
\RequirePackage{etex} % Solves many errors caused by tikz or pgf
\RequirePackage{amssymb}
\RequirePackage{amsthm}
\RequirePackage{mathtools} % includes amsmath package
\RequirePackage{graphicx}
\RequirePackage{hyperref}
\RequirePackage[sort]{natbib}
\RequirePackage{rotating}
\RequirePackage{multirow}
\RequirePackage{bm}
\RequirePackage{multicol}
\RequirePackage{enumerate}
\RequirePackage[us, 12hr]{datetime}
\RequirePackage{float}
\RequirePackage{bigstrut}
\RequirePackage{array}
\RequirePackage{tikz}
\RequirePackage{caption}
\RequirePackage{epstopdf}

% ------------ Private Notes Packages -------------------------------------------------------------
\mode<article>{
\RequirePackage{fancyhdr}
\RequirePackage[margin=1in]{geometry}
\RequirePackage{setspace}
\RequirePackage{tcolorbox} %used to make nice blocks in private notes
\tcbuselibrary{skins}%,breakable}
\RequirePackage{ifthen} %used to hide title bar in blocks
}

% ------------ Colors (Try to only use these so the theme is consistent)---------------------------
\definecolor{UCMaroon}{RGB}{128,0,0}
\definecolor{UCDarkGray}{RGB}{118,118,118}
\definecolor{UCLightGray}{RGB}{214,214,206}
\definecolor{UCRed}{RGB}{143,57,49}
\definecolor{UCYellowOrange}{RGB}{193,102,34}
\definecolor{UCLightGreen}{RGB}{138,157,69}
\definecolor{UCDarkGreen}{RGB}{88,89,63}
\definecolor{UCBlue}{RGB}{21,95,131}
\definecolor{UCViolet}{RGB}{53,14,32}

%--------------------- Beamer Configuration for all themes ----------------------------------------

\mode<presentation>{
\if@hceoMode                                %HECO TEMPLATE STUFF
\newcommand{\toplogo}{images/logo.png}			% Custom logo
\usetikzlibrary{backgrounds}
\else

\useoutertheme{split}
\useinnertheme[shadow=false]{rounded}
\setbeamertemplate{itemize items}[circle]
\setbeamertemplate{enumerate items}[circle]
\setbeamertemplate{sections/subsections in toc}[square]
\setbeamersize{text margin left=0.2 in}
\setbeamersize{text margin right=0.2 in}
\fi

\setbeamerfont{frametitle}{size=\small}
\setbeamerfont{infolines}{size=\footnotesize}

%% ----- The next 3 lines allow natbib to work properly in a Beamer Document ----------------------
\def\newblock{\beamer@[EMAIL PROTECTED]}

%------------ Point-block definition --------------------------------------------------------------
\newcounter{PointCtr}
\setcounter{PointCtr}{0}
\resetcounteronoverlays{PointCtr}
\newenvironment{point-block}
    {
        \stepcounter{PointCtr}
        \begin{block}{}
        \textbf{\thePointCtr}.~
    }
    {
        \end{block}
    }
}
% -------------- End Presentation Configuration ---------------------------------------------------



\if@staticDisplay
% ---------------------- STATIC Theme -------------------------------------------------------------
\mode<handout>{
\hypersetup{pdfpagemode=FullScreen}

\if@hceoMode
\usetheme[
	bullet=circle,		% Other option: square
	%bigpagenumber,		% circled page number on lower right
	%handoutmode,		% Adds Page Numbers and Revision Date to Footer
	topline=true,			% colored bar at the top of the frame
	shadow=false,			% Shading for beamer blocks
	]{Flip}
\else

\setbeamercolor{structure}{bg=UCLightGray, fg=UCMaroon}

\setbeamercolor{palette primary}{fg=white, bg=UCMaroon}
%\setbeamercolor{palette secondary}{use=structure,fg=UCDarkGreen,bg=UCRed} %Not used
%\setbeamercolor{palette tertiary}{use=structure,fg=UCViolet,bg=UCBlue} %Not used
\setbeamercolor{palette quaternary}{fg=white,bg=UCDarkGray}
\setbeamercolor{section number projected}{fg=white, bg=UCYellowOrange}
\setbeamercolor{itemize item}{fg=UCYellowOrange}
\setbeamercolor{itemize subitem}{fg=UCLightGreen}
\setbeamercolor{itemize subsubitem}{fg=UCViolet}

\setbeamercolor{item projected}{bg=UCBlue}
\setbeamercolor{subitem projected}{bg=UCRed}
\setbeamercolor{subsubitem projected}{bg=UCDarkGreen}

\setbeamercolor{enumerate item}{fg=UCBlue}
\setbeamercolor{enumerate subitem}{fg=UCRed}
\setbeamercolor{enumerate subsubitem}{fg=UCDarkGreen}

\setbeamercolor{block title}{fg=white, bg=UCMaroon}
\setbeamercolor{block body}{fg=black, bg=UCLightGray}
\setbeamercolor{title}{fg=white, bg=UCMaroon}
\setbeamercolor{frametitle}{fg=white, bg=UCMaroon}

\if@hceoLogoMode
\logo{\vspace{-2.2mm}\includegraphics[height=1cm]{images/logo_trans.png}}
\else
\logo{\vspace{-2mm}\includegraphics[height=0.7cm]{UChicago_SPOT_LightGRAY.pdf}}
\fi

\setbeamertemplate{footline}
{
 \leavevmode%
 \hbox{%
 \begin{beamercolorbox}[wd=.5\paperwidth,ht=2.25ex,dp=1ex,center]{author in head/foot}%
   \usebeamerfont{author in head/foot}\insertshortauthor
 \end{beamercolorbox}%
 \begin{beamercolorbox}[wd=.5\paperwidth,ht=2.25ex,dp=1ex,center]{title in head/foot}%
   \usebeamerfont{title in head/foot}\insertshorttitle
 \end{beamercolorbox}%
 }%
}

\setbeamertemplate{headline}
{
  \leavevmode%
  \hbox{%
    \begin{beamercolorbox}[wd=\paperwidth,ht=2.25ex,dp=1ex,center]{section in head/foot}%
      \insertsectionnavigationhorizontal{\paperwidth}{}{}%
     \end{beamercolorbox}}
}
\fi
}
\fi
%---------------------- END OF STATIC THEME -------------------------------------------------------

% ----------------------- PRINT Theme -------------------------------------------------------------
\if@handoutMode
\mode<handout>{
\if@hceoMode
\usetheme[
	bullet=circle,		% Other option: square
	%bigpagenumber,		% circled page number on lower right
	handoutmode,		% Adds Page Numbers and Revision Date to Footer
	topline=true,			% colored bar at the top of the frame
	shadow=false,			% Shading for beamer blocks
	]{Flip}
\else
\usecolortheme{seahorse}
\usecolortheme{rose}

\if@hceoLogoMode
\logo{\vspace{-2mm}\includegraphics[height=1cm]{images/logo_trans.png}}
\else
\logo{\vspace{-2mm}\includegraphics[height=0.7cm]{UChicago_SPOT_LightGRAY.pdf}}
\fi

\setbeamertemplate{footline}
{
 \leavevmode%
 \hbox{%
 \begin{beamercolorbox}[wd=.3\paperwidth,ht=2.25ex,dp=1ex,center]{author in head/foot}%
   \usebeamerfont{author in head/foot}\insertshortauthor
 \end{beamercolorbox}%
 \begin{beamercolorbox}[wd=.6\paperwidth,ht=2.25ex,dp=1ex,center]{title in head/foot}%
   \usebeamerfont{title in head/foot}\insertshorttitle , \ \today~\currenttime
 \end{beamercolorbox}%
 \begin{beamercolorbox}[wd=.1\paperwidth,ht=2.25ex,dp=1ex,right]{date in head/foot}%
   \insertframenumber{} / \inserttotalframenumber\hspace*{2ex}
 \end{beamercolorbox}}%
}
\setbeamertemplate{headline}
{
  \leavevmode%
  \hbox{%
    \begin{beamercolorbox}[wd=\paperwidth,ht=2.25ex,dp=1ex,center]{section in head/foot}%
      \insertsectionnavigationhorizontal{\paperwidth}{}{}%
     \end{beamercolorbox}}
}
\fi
}
\fi
%------------------------ End of PRINT Theme-------------------------------------------------------

% --------------------------- DYNAMIC Theme -------------------------------------------------------

\mode<beamer>{

\hypersetup{pdfpagemode=FullScreen}
\if@hceoMode
\usetheme[
	bullet=circle,		% Other option: square
	%bigpagenumber,		% circled page number on lower right
	%handoutmode,		% Adds Page Numbers and Revision Date to Footer
	topline=true,			% colored bar at the top of the frame
	shadow=false,			% Shading for beamer blocks
	]{Flip}
\else

\beamertemplatenavigationsymbolsempty

\setbeamercolor{structure}{bg=UCLightGray, fg=UCMaroon}

\setbeamercolor{palette primary}{fg=white, bg=UCMaroon}
%\setbeamercolor{palette secondary}{use=structure,fg=UCDarkGreen,bg=UCRed} %Not used
%\setbeamercolor{palette tertiary}{use=structure,fg=UCViolet,bg=UCBlue} %Not used
\setbeamercolor{palette quaternary}{fg=white,bg=UCDarkGray}
\setbeamercolor{section number projected}{fg=white, bg=UCYellowOrange}
\setbeamercolor{itemize item}{fg=UCYellowOrange}
\setbeamercolor{itemize subitem}{fg=UCLightGreen}
\setbeamercolor{itemize subsubitem}{fg=UCViolet}

\setbeamercolor{item projected}{bg=UCBlue}
\setbeamercolor{subitem projected}{bg=UCRed}
\setbeamercolor{subsubitem projected}{bg=UCDarkGreen}

\setbeamercolor{enumerate item}{fg=UCBlue}
\setbeamercolor{enumerate subitem}{fg=UCRed}
\setbeamercolor{enumerate subsubitem}{fg=UCDarkGreen}

\setbeamercolor{block title}{fg=white, bg=UCMaroon}
\setbeamercolor{block body}{fg=black, bg=UCLightGray}
\setbeamercolor{title}{fg=white, bg=UCMaroon}
\setbeamercolor{frametitle}{fg=white, bg=UCMaroon}

\if@hceoLogoMode
\logo{\vspace{-2mm}\includegraphics[height=0.7cm]{images/logo_trans.png}}
\else
\logo{\vspace{-2mm}\includegraphics[height=0.7cm]{UChicago_SPOT_LightGRAY.pdf}}
\fi

  \setbeamertemplate{footline}
{
 \leavevmode%
 \hbox{%
 \begin{beamercolorbox}[wd=.5\paperwidth,ht=2.25ex,dp=1ex,center]{author in head/foot}%
   \usebeamerfont{author in head/foot}\insertshortauthor
 \end{beamercolorbox}%
 \begin{beamercolorbox}[wd=.5\paperwidth,ht=2.25ex,dp=1ex,center]{title in head/foot}%
   \usebeamerfont{title in head/foot}\insertshorttitle
 \end{beamercolorbox}%
 }%
}
\setbeamertemplate{headline}
{
  \leavevmode%
  \hbox{%
    \begin{beamercolorbox}[wd=\paperwidth,ht=2.25ex,dp=1ex,center]{section in head/foot}%
      \insertsectionnavigationhorizontal{\paperwidth}{}{}%
     \end{beamercolorbox}}
}
\fi
}

%-------------------- End of DISPLAY Theme --------------------------------------------------------

\if@hceoMode                                %HCEO TEMPLATE STUFF
\mode<presentation>{

%----- Redefine block environment to accommodate logo (FOR HECO THEME) -----------------------------
\addtobeamertemplate{block begin}{%
  \setlength{\textwidth}{0.9\textwidth}%
}{}

\addtobeamertemplate{block alerted begin}{%
  \setlength{\textwidth}{0.9\textwidth}%
}{}

\addtobeamertemplate{block example begin}{%
  \setlength{\textwidth}{0.9\textwidth}%
}{}

}
\fi

% ---------- Private Notes Configuration ----------------------------------------------------------
\mode<article>{

\captionsetup{font=Large,labelfont=Large}

\setlength{\parskip}{1mm plus 0.75mm minus 0.75mm}

\widowpenalty=500
\clubpenalty=500

% Reenables "\\" (Disabled in frames in article mode by Beamer author)
\makeatletter
\let\beamer@@breaker\beamer@origbreak
\let\beamer@@breakercenter\beamer@origbreakcenter
\makeatother


%------------ Point-block definition --------------------------------------------------------------

\newcounter{PointCtr}
\setcounter{PointCtr}{0}
\newenvironment{point-block}
    {
        \stepcounter{PointCtr}
        \begin{block}{}
        \textbf{\thePointCtr}.~
    }
    {
        \end{block}
    }


% -------- Defining Beamer Environments for Private Notes -----------------------------------------
\newsavebox{\mybox}
\newsavebox{\blockbox}

\setbeamertemplate{frame begin}
{\setbox\mybox=\vbox\bgroup}

\setbeamertemplate{frame end}
{\egroup \noindent\fbox{\usebox{\mybox}}\\ \ \\

}

\renewcommand{\frametitle}[1]{#1}

% Old Frame redefinition, leaving it in incase new one breaks something.
%\renewenvironment{frame}%
%{\setbox\mybox=\vbox\bgroup}%
%{\egroup \noindent\fbox{\usebox{\mybox}}\\
%
%}



% ----------------------------- Header stuff ------------------------------------------------------
\pagestyle{fancy}
\lhead{\theshorttitle}
\rhead{\today~\currenttime}

% -------------------- Command to hide sections in private notes ----------------------------------
% Use after the table of contents command in the file.
\newcommand{\hidesections}{
\renewcommand{\section}[2][]{%
 \refstepcounter{section}%
 \addcontentsline{toc}{section}{\protect\numberline{\thesection}##2}%
 \markright{##2}}
}

}
% ------------------------- End Private Notes Configuration ---------------------------------------

% ------------ Configuration for all files --------------------------------------------------------

% ------------ Additional Math Commands -----------------------------------------------------------

\newcommand{\orth}{\ensuremath{\perp\!\!\!\perp}}%
\newcommand{\indep}{\orth}%
\newcommand{\notorth}{\ensuremath{\perp\!\!\!\!\!\!\diagup\!\!\!\!\!\!\perp}}%
\newcommand{\notindep}{\notorth}%
\DeclareMathOperator{\argmax}{argmax}%
\DeclareMathOperator{\argmin}{argmin}%
\DeclareMathOperator{\Cov}{Cov}%
\DeclareMathOperator{\cov}{Cov}%
\DeclareMathOperator{\plim}{plim}%
\DeclareMathOperator{\Supp}{Supp}%
\DeclareMathOperator{\Var}{Var}

%------------------ Bold and italic ---------------------------------------------------------------
\DeclareMathAlphabet{\mathitbf}{OML}{cmm}{b}{it}


%---------------- Tables, Figures, and Theorems numbered ------------------------------------------

\setbeamertemplate{caption}[numbered]
\setbeamertemplate{theorems}[numbered]

%------------- Save box to hide bibliography in ---------------------------------------------------
\newsavebox\hiddenbib


% -------------- defining stuff for title pages, redefined in the latex ---------------------------

\def \thetitle {\ } % Full title goes here

\def \theshorttitle {\ } %Short title goes here

\def \theauthor {\ } % Author name(s) go here

\def \theshortauthor {\ } % Short author name(s) go here; should fit on this one line.

\def \thedate {\ } % Date and venue information

\def \eventnotes {\ } % Other event info, to appear on the front of the private notes

%%----- Title Page (DO NOT EDIT)-------------------------------------------------------------------
\title[\theshorttitle]{\thetitle}

\author[\theshortauthor]{\theauthor}

\date{\thedate%
\if@handoutMode%
\mode<handout>{\\ This draft, \today~\currenttime}%
\fi%
\mode<article>{\\ This draft, \today~\currenttime}
}

\if@hceoMode
\institute{\ \\[3mm] \includegraphics[height=.5in]{images/uchicago.png}\hfill\hfill\includegraphics[height=.5in]{images/logohorizontal.png}\hfill\hfill\includegraphics[height=.5in]{images/CEHD-logo.eps}}
\fi

%% ---------------------- Defining Presentation Title Page (HECO and Normal) -----------------------

\if@hceoMode
\def \thePresentationTitle {%
\mode<presentation>

\tikzstyle{every picture}+=[remember picture]

{
\setbeamertemplate{sidebar right}{\llap{\includegraphics[width=\paperwidth,height=\paperheight]{images/BG_upper}}}

\setbeamercolor{background canvas}{bg=coolgray}
\maketitle

}

\mode*
}
\else
\def \thePresentationTitle {%
\begin{frame}
\maketitle
\end{frame}
}
\fi

% ----------------------- Macro for dropping in title pages ---------------------------------------

\def \theTitlePages {%
% ---------------------- Private Notes Title Page (DO NOT EDIT)------------------------------------
\mode<article>{
\setlength\fboxsep{5 pt} % putting padding on the fboxes

\thispagestyle{plain}
\begin{center} \LARGE
    Private Notes For:\\
    \thetitle\\ \ \\

    \theauthor\ \\ \ \\

    \thedate\\
    This draft, \today~\currenttime
\end{center}

\vspace{1in}

\Large %setting font size for entire document

\noindent\eventnotes

\clearpage
}

%% ----------------- Presentation Title Page (DO NOT EDIT) ----------------------------------------
\mode<all>{\thePresentationTitle}

\thispagestyle{fancy}

}
% -------------------------------- End of Title Page(s) -------------------------------------------
