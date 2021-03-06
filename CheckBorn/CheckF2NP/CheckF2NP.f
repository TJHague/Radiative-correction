        program CheckF2NP
        implicit none

        real*8 CJ_F2N,CJ_F2P,F2_NP,F2_NP_1,F2_NP_2
        real*8 x,Z,A,Q2,AX,BX
        character*80 outfile
        integer ii

        real*8 CJsfn
        external CJsfn
        

        outfile='OUT/F2NP.out'
        open(unit=66,file=outfile)
        write(66,*) 'x   F2n/F2p_SLAC CJ15 '


        A=3.0
        Z=1.0

        call setCJ(600)

        do 99 ii=1,99
           x=0.+0.01*ii
           Q2=14.*x

           F2_NP=1-0.8*x

           CJ_f2p=CJsfn(7,x,sqrt(Q2))
           CJ_f2n=CJsfn(8,x,sqrt(Q2))
           F2_NP_1=CJ_f2n/CJ_f2p

           AX=0.979-1.692*x+2.797*x**2-4.313*x**3+3.075*x**4
           BX=-0.171*x+0.244*x**2
           F2_np_2=AX*((Q2/20.0)**BX)*(1+x**2/Q2)

           write(66,'(4F13.5)') x,F2_NP,F2_NP_1,F2_NP_2

99      continue


        return
        end

