	subroutine sigmodel_calc(e1pass,e2pass,thpass,zpass,apass,mpass,sig_dis_pass,sig_qe_pass,sig,xflag,factpass,model)
C       +______________________________________________________________________________
c	
C       Calculate cross section using Peter's F1F209.f routine
c       
c       ARGUMENTS:
c       
c       E1:		-	Incident energy in GeV.
c       E2:		- Scattered energy in GeV.
c       TH:		- Scattering angle in Degrees.
c       A:		- 'A' of nucleus.
c       Z:		- Number of protons in nucleus.
c       M_TGT:	- Mass of target nucleus in GeV/c2.
c       M_REC:	- Mass of recoiling nucleon in GeV/c2.
c       E_SEP:	- Separation energy for target nucleus in GeV/c2.
c       SIG  :	- Calculated cross section in nb/(MeV-ster).// should be nb/(GeV-ster)
c       model:  first digit -- F2d model: 1=Bodek, 2=Eric, 3=NMC
c               second digit -- EMC model: 1=KP, 2=Close
c               third digit --F2n/F2p model: 1=curve1, 2=crve2, 3=curve3 
c                             used to remove isoscalar correction in EMC ratio
c               exp: 111 = Bodek F2d + KP EMC + curve1 F2n/F2p
C       ______________________________________________________________________________

        implicit none
	include 'math_physics.inc'
	include 'include.inc'

C       Declare arguments.

	real*8		e1,e2,th,a,z,m_tgt
	real*4          e1pass,e2pass,thpass,mpass
	real*4          sig,factpass,sig_dis_pass,sig_qe_pass
	integer         zpass,apass
	logical		modelhack

C       Declare locals.

	real*8	 	sig_qe,sig_dis,y,normfac,fact
        real*8		thr,cs,sn,tn,elastic_peak
	real*8          Q2,nu,WSQ, x
	real*8          F1,F2,FL,W1,W2,sigmott,r
	real*8          W1p,W1n,W1D,W2p,W2n,W2D,F2D,F1D
	integer         xflag !flag for which xsec to calculate 1=both 2=QE only 3=DIS only
	logical         first
        integer         D2_MODEL,EMC_MODEL,NP_MODEL,model  !DIS_MODEL defined in TARG
        real*8          eps
        real*8          kappa,flux
        integer         wfn,opt
        logical         doqe,dfirst/.false./
        real*8          pi2,alp
        real*8          emccor

	save

        real*8 emc_KP
	external emc_KP

	real*8 emc_func_slac
	external emc_func_slac

	data first/.true./

	e1=dble(e1pass)
	e2=dble(e2pass)
	th=dble(thpass)
	a=dble(apass)
	z=dble(zpass)
	m_tgt=dble(mpass)
        alp = 1./137.036
        pi2 = 3.14159*3.14159

        D2_MODEL=MODEL/100
        EMC_MODEL=(MODEL-D2_MODEL*100)/10
        NP_MODEL=MODEL-D2_MODEL*100-EMC_MODEL*10
	sig =0.0
	sig_qe=0.0
	sig_dis=0.0

C       If at or beyond elastic peak, return ZERO!

	thr = th*d_r
	cs = cos(thr/2.)
	sn = sin(thr/2.)
	tn = tan(thr/2.)
	elastic_peak = e1/(1.+2.*e1*sn**2/m_tgt)
      	if (e2.ge.elastic_peak) then
       	   sig = 0.0
       	   return
       	endif
c	write(6,*) 'got to 1'

	Q2 = 4.*e1*e2*sn**2
	nu=e1-e2
	WSQ = -Q2 + m_p**2 + 2.0*m_p*nu 
        x = Q2/2/m_p/nu
        eps = 1.0/(1+2.*(1+Q2/(4*m_p**2*x**2))*tn**2)
        kappa = abs((wsq-m_p**2))/2./m_p
        flux = alp*kappa/(2.*pi2*Q2)*e2/e1/(1.-eps)
        wfn=2

	F1=0
	F2=0
	r=0
	if((xflag.eq.1).or.(xflag.eq.3)) then
c----------------------------------------------------------------
c       
c       do inelastic stuff
c	   call F1F2IN09(Z, A, Q2, WSQ, F1, F2, r)
C Use old Bodek fit + SLAC EMC fit for now, b/c F1F2IN09 doesn't like large Q2,W2
	  if(wsq.gt.1.1664) then
            if(A .eq. 1.0) then
               call ineft(Q2,sqrt(wsq),W1p,W2p,dble(1.0))
               F2 = nu*W2p
               F1 = m_p*W1p
            endif 

            if(A .gt. 1.0) then         
              if(D2_MODEL .eq. 1) then
	         call ineft(Q2,sqrt(wsq),W1p,W2p,dble(1.0))
	         call ineft(Q2,sqrt(wsq),W1D,W2D,dble(2.0))
        
                 F2D=nu*W2D*2.0
                 F1D=m_p*W1D*2.0
              endif

              emccor=1.0
              if(EMC_MODEL .eq. 1) then
                 emccor=EMC_KP(x,Z,A)
              endif

              F2=F2D*emccor
              F1=F1D*emccor
            endif

            sigmott=(19732.0/(2.0*137.0388*e1*sn**2))**2*cs**2/1.d6
            sig_dis = 1d3*sigmott*(F2/nu+2.0*F1/m_p*tn**2)
	  endif


	endif

        if((xflag.eq.1).or.(xflag.eq.2)) then
           call F1F2QE09(Z, A, Q2, WSQ, F1, F2)
C       Convert F1,F2 to W1,W2
           W1 = F1/m_p
           W2 = F2/nu
C       Mott cross section
           sigmott=(19732.0/(2.0*137.0388*e1*sn**2))**2*cs**2/1.d6
           sig_qe = 1d3*sigmott*(W2+2.0*W1*tn**2)
C Temp test - DJG May 23, 2013
c          sig_qe=sig_qe/0.8
        endif

	sig = sig_qe + sig_dis !sig is already real*4


	sig_qe_pass = sig_qe ! pass back as real*4
	sig_dis_pass = sig_dis

	return
	end


c-------------------------------------------------------------------------------------------
	real*8 function emc_func_slac(x,A)
	real*8 x,A,atemp
	real*8 alpha,C

	atemp = A
!	if(A.eq.4.or.A.eq.3) then  ! emc effect is more like C for these 2...
!	   atemp = 12
!	endif

	alpha = -0.070+2.189*x - 24.667*x**2 + 145.291*x**3
	1    -497.237*x**4 + 1013.129*x**5 - 1208.393*x**6
	2    +775.767*x**7 - 205.872*x**8

	C = exp( 0.017 + 0.018*log(x) + 0.005*log(x)**2)
	
	emc_func_slac = C*atemp**alpha
	return 
	end      

c---------------------------------------------------------------------------------------------

        real*8 function emc_KP(x,Z,A)
        real*8 x,Z,A

        emc_KP = 1.0
        if((Z .EQ. 1.0) .and. (A .eq. 3.0)) then
          emc_KP = 1.07251-1.61648*x+12.3626*x**2-65.5932*x**3+213.311*x**4
     >           -423.943*x**5+499.994*x**6-321.304*x**7+87.0596*x**8
          emc_KP = emc_KP*A/2.0
        endif

        if((Z .EQ. 2.0) .and. (A .eq. 3.0)) then
          emc_KP = 1.02967-0.135929*x+3.92009*x**2-21.2861*x**3
     >           +64.7762*x**4-129.928*x**5+169.609*x**6
     >           -127.386*x**7+41.0723*x**8
          emc_KP = emc_KP*A/2.0
        endif

        return
        end

c----------------------------------------------------------------------------------------------
