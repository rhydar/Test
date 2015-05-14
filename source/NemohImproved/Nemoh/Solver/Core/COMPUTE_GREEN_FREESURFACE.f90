!--------------------------------------------------------------------------------------
!
!Copyright (C) 2014 TopCoder Inc., All Rights Reserved.
!
!--------------------------------------------------------------------------------------

!--------------------------------------------------------------------------------------
!
!   Copyright 2014 Ecole Centrale de Nantes, 1 rue de la No�, 44300 Nantes, France
!
!   Licensed under the Apache License, Version 2.0 (the "License");
!   you may not use this file except in compliance with the License.
!   You may obtain a copy of the License at
!
!       http://www.apache.org/licenses/LICENSE-2.0
!
!   Unless required by applicable law or agreed to in writing, software
!   distributed under the License is distributed on an "AS IS" BASIS,
!   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!   See the License for the specific language governing permissions and
!   limitations under the License. 
!
!   Contributors list:
!   - G. Delhommeau
!   - P. Gu�vel
!   - J.C. Daubisse
!   - J. Singh  
!
!--------------------------------------------------------------------------------------

!   This module contains utilities that will be used to compute the free surface elevation for a given
!   problem.
!
! Changes in version 1.2 (Implementation of Higher Order Panel Methods)
!       Added COMMON_TYPE module as dependency
!
! Changes in version 1.3 (Dipoles Implementation in NEMOH)
!       Updated the subroutine to accept an additional parameter indicating the type
!       of derivative to perform
!
!   @author yedtoss
!   @version 1.3
MODULE COMPUTE_GREEN_FREESURFACE

    USE COMMON_TYPE
    USE COM_VAR
    USE ELEMENTARY_FNS

    IMPLICIT NONE

CONTAINS
    !-------------------------------------------------------------------------------!
    SUBROUTINE VVV(deriv, KKK,J,XOI,YOI,ZOI,  SolverVar)

        INTEGER:: deriv ! 1 for computing the derivative with respect to source point, 2 for field point
        ! It is only needed and supported currently when there is no symmetry around OxZ
        INTEGER:: KKK,J,NJJ,JJ,L,MJJ
        INTEGER:: MK,MV,MH,MY,MZ
        INTEGER:: KK(5)
        REAL:: XOI,YOI,ZOI,XOJ,YOJ,ZOJ
        REAL:: DHSL,A3J,A6J,A9J
        REAL:: ALDEN,ANL,ANLX,ANLY,ANLZ,ANTX,ANTY,ANTZ
        REAL:: ARG,ASRO,AT,ATX,ATY,ATZ,DAT,DDK,DEN,DENL,DENT,DK,DLOGG
        REAL:: ANT,DNL,DNT,DNTX,DNTY,DNTZ,DR,DS,GY,GYX,GYZ,GZ,PJ,QJ,RJ,RO,SGN,W
        REAL:: PI,PI4,DPI,QPI,GYY
        REAL:: RR(5),DRX(5),DRY(5),DRZ(5)
        REAL:: TXN(5),TYN(5),TZN(5),AIJS(4),VXS(4),VYS(4),VZS(4)
        TYPE(TempVar), TARGET :: SolverVar
REAL, POINTER :: T
COMPLEX, DIMENSION(:), POINTER :: ZPB,ZPS
COMPLEX, DIMENSION(:), POINTER :: ZIGB,ZIGS
COMPLEX, DIMENSION(:, :), POINTER :: ZIJ
REAL, POINTER :: FSP,FSM,VSXP,VSYP,VSZP,VSXM,VSYM,VSZM
REAL, POINTER :: SP1,SM1,SP2,SM2
REAL, POINTER :: VSXP1,VSXP2,VSYP1,VSYP2,VSZP1,VSZP2
REAL, POINTER :: VSXM1,VSXM2,VSYM1,VSYM2,VSZM1,VSZM2
INTEGER, POINTER:: NQ
REAL, POINTER:: CQ(:),QQ(:),AMBDA(:),AR(:)
T => SolverVar%T
ZPB => SolverVar%ZPB
ZPS => SolverVar%ZPS
ZIGB => SolverVar%ZIGB
ZIGS => SolverVar%ZIGS
ZIJ => SolverVar%ZIJ
FSP => SolverVar%FSP
FSM => SolverVar%FSM
VSXP => SolverVar%VSXP
VSYP => SolverVar%VSYP
VSZP => SolverVar%VSZP
VSXM => SolverVar%VSXM
VSYM => SolverVar%VSYM
VSZM => SolverVar%VSZM
SP1 => SolverVar%SP1
SM1 => SolverVar%SM1
SP2 => SolverVar%SP2
SM2 => SolverVar%SM2
VSXP1 => SolverVar%VSXP1
VSXP2 => SolverVar%VSXP2
VSYP1 => SolverVar%VSYP1
VSYP2 => SolverVar%VSYP2
VSZP1 => SolverVar%VSZP1
VSZP2 => SolverVar%VSZP2
VSXM1 => SolverVar%VSXM1
VSXM2 => SolverVar%VSXM2
VSYM1 => SolverVar%VSYM1
VSYM2 => SolverVar%VSYM2
VSZM1 => SolverVar%VSZM1
VSZM2 => SolverVar%VSZM2
NQ => SolverVar%NQ
CQ => SolverVar%CQ
QQ => SolverVar%QQ
AMBDA => SolverVar%AMBDA
AR => SolverVar%AR

        PI4=ATAN(1.)
        PI=4.*PI4
        DPI=2.*PI
        QPI=4.*PI
        DHSL=2*Depth
        NJJ=NSYMY+1
        IF(KKK.EQ.1)THEN
            MK=1           !second form of the greens function is used 1/r+1/r1
            MV=-1
        ELSE
            MK=-1
            MV=-1
        ENDIF

        DO JJ=1,2*NJJ
            MJJ=(-1)**(JJ+1)
            MY=(-1)**(JJ/3+2)
            MZ=(-1)**(JJ/2+2)
            MH=(1-(-1)**(JJ/2+2))/2
            XOJ=XG(J)
            YOJ=YG(J)*MY
            ZOJ=ZG(J)*MZ-DHSL*MH
            A3J=XN(J)
            A6J=YN(J)*MY
            A9J=ZN(J)*MZ
            RO=SQRT((XOI-XOJ)**2+(YOI-YOJ)**2+(ZOI-ZOJ)**2)
            IF(RO.GT.7.*TDIS(J))THEN
                AIJS(JJ)=AIRE(J)/RO
                ASRO=AIJS(JJ)/RO**2
                VXS(JJ)=-(XOI-XOJ)*ASRO
                VYS(JJ)=-(YOI-YOJ)*ASRO
                VZS(JJ)=-(ZOI-ZOJ)*ASRO
            ELSE
                AIJS(JJ)=0.
                VXS(JJ)=0.
                VYS(JJ)=0.
                VZS(JJ)=0.
                KK(1)=M1(J)
                KK(2)=M2(J)
                KK(3)=M3(J)
                KK(4)=M4(J)
                KK(5)=KK(1)
                DO L=1,4
                    TXN(L)=X(KK(L))
                    TYN(L)=Y(KK(L))*MY
                    TZN(L)=Z(KK(L))*MZ-DHSL*MH
                END DO
                TXN(5)=TXN(1)
                TYN(5)=TYN(1)
                TZN(5)=TZN(1)
                DO L=1,4
                    RR(L)=SQRT((XOI-TXN(L))**2+(YOI-TYN(L))**2+(ZOI-TZN(L))**2)
                    DRX(L)=(XOI-TXN(L))/RR(L)
                    DRY(L)=(YOI-TYN(L))/RR(L)
                    DRZ(L)=(ZOI-TZN(L))/RR(L)
                END DO
                RR(5)=RR(1)
                DRX(5)=DRX(1)
                DRY(5)=DRY(1)
                DRZ(5)=DRZ(1)
                GZ=(XOI-XOJ)*A3J+(YOI-YOJ)*A6J+(ZOI-ZOJ)*A9J
                DO L=1,4
                    DK=SQRT((TXN(L+1)-TXN(L))**2+(TYN(L+1)-TYN(L))**2+(TZN(L+1)-TZN(L))**2)
                    IF(DK.GE.1.E-3*TDIS(J))THEN
                        PJ=(TXN(L+1)-TXN(L))/DK
                        QJ=(TYN(L+1)-TYN(L))/DK
                        RJ=(TZN(L+1)-TZN(L))/DK
                        GYX=A6J*RJ-A9J*QJ
                        GYY=A9J*PJ-A3J*RJ
                        GYZ=A3J*QJ-A6J*PJ
                        GY=(XOI-TXN(L))*GYX+(YOI-TYN(L))*GYY+(ZOI-TZN(L))*GYZ
                        SGN=SIGN(1.,GZ)
                        DDK=2.*DK
                        ANT=GY*DDK
                        DNT=(RR(L+1)+RR(L))**2-DK*DK+2.*ABS(GZ)*(RR(L+1)+RR(L))
                        ARG=ANT/DNT
                        ANL=RR(L+1)+RR(L)+DK
                        DNL=RR(L+1)+RR(L)-DK
                        DEN=ANL/DNL
                        ALDEN=ALOG(DEN)
                        IF(ABS(GZ).GE.1.E-4*TDIS(J))THEN
                            AT=ATAN(ARG)
                        ELSE
                            AT=0.
                        ENDIF
                        AIJS(JJ)=AIJS(JJ)+GY*ALDEN-2.*ABS(GZ)*AT
                        DAT=2.*AT*SGN
                        ANTX=GYX*DDK
                        ANTY=GYY*DDK
                        ANTZ=GYZ*DDK
                        ANLX=DRX(L+1)+DRX(L)
                        ANLY=DRY(L+1)+DRY(L)
                        ANLZ=DRZ(L+1)+DRZ(L)
                        DR=2.*(RR(L+1)+RR(L)+ABS(GZ))
                        DS=2.*(RR(L+1)+RR(L))*SGN
                        DNTX=DR*ANLX+A3J*DS
                        DNTY=DR*ANLY+A6J*DS
                        DNTZ=DR*ANLZ+A9J*DS
                        DENL=ANL*DNL
                        DENT=ANT*ANT+DNT*DNT
                        ATX=(ANTX*DNT-DNTX*ANT)/DENT
                        ATY=(ANTY*DNT-DNTY*ANT)/DENT
                        ATZ=(ANTZ*DNT-DNTZ*ANT)/DENT
                        DLOGG=(DNL-ANL)/DENL
                        VXS(JJ)=VXS(JJ)+GYX*ALDEN+GY*ANLX*DLOGG-2.*ABS(GZ)*ATX-DAT*A3J
                        VYS(JJ)=VYS(JJ)+GYY*ALDEN+GY*ANLY*DLOGG-2.*ABS(GZ)*ATY-DAT*A6J
                        VZS(JJ)=VZS(JJ)+GYZ*ALDEN+GY*ANLZ*DLOGG-2.*ABS(GZ)*ATZ-DAT*A9J
                    ENDIF
                END DO
                AIJS(JJ)=AIJS(JJ)*MJJ
                VXS(JJ)=VXS(JJ)*MJJ
                VYS(JJ)=VYS(JJ)*MJJ
                VZS(JJ)=VZS(JJ)*MJJ
            ENDIF
        END DO

        IF(NSYMY.EQ.1)THEN
            W=AIJS(1)-MK*(AIJS(2)+AIJS(3))+AIJS(4)
            SolverVar%FSP=-W/QPI
            W=AIJS(1)-MK*(AIJS(2)-AIJS(3))-AIJS(4)
            SolverVar%FSM=-W/QPI
            W=VXS(1)-MV*(VXS(2)+VXS(3))+VXS(4)
            SolverVar%VSXP=-W/QPI
            W=VYS(1)-MV*(VYS(2)+VYS(3))+VYS(4)
            SolverVar%VSYP=-W/QPI
            W=VZS(1)-MV*(VZS(2)+VZS(3))+VZS(4)
            SolverVar%VSZP=-W/QPI
            W=VXS(1)-MV*(VXS(2)-VXS(3))-VXS(4)
            SolverVar%VSXM=-W/QPI
            W=VYS(1)-MV*(VYS(2)-VYS(3))-VYS(4)
            SolverVar%VSYM=-W/QPI
            W=VZS(1)-MV*(VZS(2)-VZS(3))-VZS(4)
            SolverVar%VSZM=-W/QPI
        ELSE
            W=AIJS(1)-MK*AIJS(2)
            SolverVar%FSP=-W/QPI
            SolverVar%FSM=FSP
            W=VXS(1)-MV*VXS(2)
            SolverVar%VSXP=-W/QPI
            SolverVar%VSXM=VSXP
            W=VYS(1)-MV*VYS(2)
            SolverVar%VSYP=-W/QPI
            SolverVar%VSYM=VSYP
            W=VZS(1)-MV*VZS(2)
            SolverVar%VSZP=-W/QPI
            SolverVar%VSZM=VSZP

            IF(deriv == 2) THEN

                SolverVar%VSXP = -SolverVar%VSXP
                SolverVar%VSXM=VSXP

                SolverVar%VSYP = -SolverVar%VSYP
                SolverVar%VSYM=VSYP

                SolverVar%VSZP=-(-VZS(1)-MV*VZS(2))/QPI
                SolverVar%VSZM=VSZP

            END IF
        ENDIF

        RETURN
    END SUBROUTINE
    !----------------------------------------------------------------

    SUBROUTINE VNV(deriv, J,XPO,YPO,ZPO,SolverVar)

        INTEGER:: deriv ! 1 for computing the derivative with respect to source point, 2 for field point
        ! It is only needed and supported currently when there is no symmetry around OxZ
        INTEGER:: J,JJ,NJJ,BX,KI,KJ
        REAL:: XPO,YPO,ZPO
        REAL:: FS1(NFA,2),FS2(NFA,2)
        REAL:: VSX1(NFA,2),VSY1(NFA,2),VSZ1(NFA,2)
        REAL:: VSX2(NFA,2),VSY2(NFA,2),VSZ2(NFA,2)
        REAL:: PI4,PI,DPI,QPI,DPI2
        REAL:: WH,WR,TR,AK0
        REAL:: EPS,ADPI,ADPI2,AKAIR,AKDPI,AKDPI2,AKP,AKP2,AKP4
        REAL:: AKR,AKZ,DD,PSURR,QJJJ,RRR,ZZZ,YMJJJ,CVX,CVY,VR1,VR2
        REAL:: CSK,DSK,EPZ,F1,F2,F3
        REAL:: PD1X,PD2X,PD1Z,PD2Z,SIK,SQ,VZ1,VZ2,XL1,XL2,XL3,ZL1,ZL2,ZL3
        TYPE(TempVar), TARGET :: SolverVar
REAL, POINTER :: T
COMPLEX, DIMENSION(:), POINTER :: ZPB,ZPS
COMPLEX, DIMENSION(:), POINTER :: ZIGB,ZIGS
COMPLEX, DIMENSION(:, :), POINTER :: ZIJ
REAL, POINTER :: FSP,FSM,VSXP,VSYP,VSZP,VSXM,VSYM,VSZM
REAL, POINTER :: SP1,SM1,SP2,SM2
REAL, POINTER :: VSXP1,VSXP2,VSYP1,VSYP2,VSZP1,VSZP2
REAL, POINTER :: VSXM1,VSXM2,VSYM1,VSYM2,VSZM1,VSZM2
INTEGER, POINTER:: NQ
REAL, POINTER:: CQ(:),QQ(:),AMBDA(:),AR(:)
T => SolverVar%T
ZPB => SolverVar%ZPB
ZPS => SolverVar%ZPS
ZIGB => SolverVar%ZIGB
ZIGS => SolverVar%ZIGS
ZIJ => SolverVar%ZIJ
FSP => SolverVar%FSP
FSM => SolverVar%FSM
VSXP => SolverVar%VSXP
VSYP => SolverVar%VSYP
VSZP => SolverVar%VSZP
VSXM => SolverVar%VSXM
VSYM => SolverVar%VSYM
VSZM => SolverVar%VSZM
SP1 => SolverVar%SP1
SM1 => SolverVar%SM1
SP2 => SolverVar%SP2
SM2 => SolverVar%SM2
VSXP1 => SolverVar%VSXP1
VSXP2 => SolverVar%VSXP2
VSYP1 => SolverVar%VSYP1
VSYP2 => SolverVar%VSYP2
VSZP1 => SolverVar%VSZP1
VSZP2 => SolverVar%VSZP2
VSXM1 => SolverVar%VSXM1
VSXM2 => SolverVar%VSXM2
VSYM1 => SolverVar%VSYM1
VSYM2 => SolverVar%VSYM2
VSZM1 => SolverVar%VSZM1
VSZM2 => SolverVar%VSZM2
NQ => SolverVar%NQ
CQ => SolverVar%CQ
QQ => SolverVar%QQ
AMBDA => SolverVar%AMBDA
AR => SolverVar%AR

        PI4=ATAN(1.)
        PI=4.*ATAN(1.)
        DPI=2.*PI
        QPI=4.*PI
        DPI2=2.*PI**2
        EPS=0.0001
        WH=DPI/SolverVar%T
        WR=WH
        TR=DPI/WR
        AK0=WR**2/9.81
        AKP=AK0/DPI
        AKP2=AK0/DPI2
        NJJ=NSYMY+1
        DO JJ=1,NJJ

            BX=(-1)**(JJ+1)
            YMJJJ=YG(J)*BX
            QJJJ=YN(J)*BX
            RRR=SQRT((XPO-XG(J))**2+(YPO-YMJJJ)**2)
            AKR=AK0*RRR
            ZZZ=ZPO+ZG(J)
            AKZ=AK0*ZZZ
            DD=SQRT(RRR**2+ZZZ**2)
            IF(DD.GT.EPS)THEN
                PSURR=PI/(AK0*DD)**3
            ELSE
                PSURR=0.
            ENDIF
            IF(AKZ.GT.-1.5E-6)THEN
                !WRITE(*,*)'AKZ < -1.5 E-6'
                !STOP Bug Fixes
                AKZ = AKZ + 0
            ELSE
                IF(AKZ.GT.-16.)THEN
                    IF(AKR.LT.99.7)THEN
                        IF(AKZ.LT.-1.E-2)THEN
                            KJ=INT(8*(ALOG10(-AKZ)+4.5))
                        ELSE
                            KJ=INT(5*(ALOG10(-AKZ)+6))
                        ENDIF
                        KJ=MAX(KJ,2)
                        KJ=MIN(KJ, TABULATION_JZ-1)
                        IF(AKR.LT.1.)THEN
                            KI=INT(5*(ALOG10(AKR+1.E-20)+6)+1)
                        ELSE
                            KI=INT(3*AKR+28)
                        ENDIF
                        KI=MAX(KI,2)
                        KI=MIN(KI,TABULATION_IR-1)
                        XL1=PL2(XR(KI),XR(KI+1),XR(KI-1),AKR)
                        XL2=PL2(XR(KI+1),XR(KI-1),XR(KI),AKR)
                        XL3=PL2(XR(KI-1),XR(KI),XR(KI+1),AKR)
                        ZL1=PL2(XZ(KJ),XZ(KJ+1),XZ(KJ-1),AKZ)
                        ZL2=PL2(XZ(KJ+1),XZ(KJ-1),XZ(KJ),AKZ)
                        ZL3=PL2(XZ(KJ-1),XZ(KJ),XZ(KJ+1),AKZ)
                        F1=XL1*APD1Z(KI-1,KJ-1)+XL2*APD1Z(KI,KJ-1)+XL3*APD1Z(KI+1,KJ-1)
                        F2=XL1*APD1Z(KI-1,KJ)+XL2*APD1Z(KI,KJ)+XL3*APD1Z(KI+1,KJ)
                        F3=XL1*APD1Z(KI-1,KJ+1)+XL2*APD1Z(KI,KJ+1)+XL3*APD1Z(KI+1,KJ+1)
                        PD1Z=ZL1*F1+ZL2*F2+ZL3*F3
                        F1=XL1*APD2Z(KI-1,KJ-1)+XL2*APD2Z(KI,KJ-1)+XL3*APD2Z(KI+1,KJ-1)
                        F2=XL1*APD2Z(KI-1,KJ)+XL2*APD2Z(KI,KJ)+XL3*APD2Z(KI+1,KJ)
                        F3=XL1*APD2Z(KI-1,KJ+1)+XL2*APD2Z(KI,KJ+1)+XL3*APD2Z(KI+1,KJ+1)
                        PD2Z=ZL1*F1+ZL2*F2+ZL3*F3
                    ELSE
                        EPZ=EXP(AKZ)
                        AKP4=AKR-PI4
                        SQ=SQRT(DPI/AKR)
                        CSK=COS(AKP4)
                        SIK=SIN(AKP4)
                        PD1Z=PSURR*AKZ-PI*EPZ*SQ*SIK
                        PD2Z=EPZ*SQ*CSK
                    ENDIF
                    VZ1=PD1Z
                    VZ2=PD2Z
                ELSE
                    PD1Z=PSURR*AKZ
                    PD2Z=0.
                    VZ1=0.
                    VZ2=0.
                ENDIF
            ENDIF
            FS1(J,JJ)=PD1Z
            FS2(J,JJ)=PD2Z
            IF(RRR.GT.EPS)THEN
                IF(AKZ.LE.-1.5E-6)THEN
                    IF(AKZ.GT.-16.)THEN
                        IF(AKR.LT.99.7)THEN
                            F1=XL1*APD1X(KI-1,KJ-1)+XL2*APD1X(KI,KJ-1)+XL3*APD1X(KI+1,KJ-1)
                            F2=XL1*APD1X(KI-1,KJ)+XL2*APD1X(KI,KJ)+XL3*APD1X(KI+1,KJ)
                            F3=XL1*APD1X(KI-1,KJ+1)+XL2*APD1X(KI,KJ+1)+XL3*APD1X(KI+1,KJ+1)
                            PD1X=ZL1*F1+ZL2*F2+ZL3*F3
                            F1=XL1*APD2X(KI-1,KJ-1)+XL2*APD2X(KI,KJ-1)+XL3*APD2X(KI+1,KJ-1)
                            F2=XL1*APD2X(KI-1,KJ)+XL2*APD2X(KI,KJ)+XL3*APD2X(KI+1,KJ)
                            F3=XL1*APD2X(KI-1,KJ+1)+XL2*APD2X(KI,KJ+1)+XL3*APD2X(KI+1,KJ+1)
                            PD2X=ZL1*F1+ZL2*F2+ZL3*F3
                        ELSE
                            DSK=0.5/AKR
                            PD1X=-PSURR*AKR-PI*EPZ*SQ*(CSK-DSK*SIK)
                            PD2X=EPZ*SQ*(SIK+DSK*CSK)
                        ENDIF
                        VR1=-PD1X
                        VR2=-PD2X
                    ELSE
                        PD1X=-PSURR*AKR
                        PD2X=0.
                        VR1=0.
                        VR2=0.
                    ENDIF
                ENDIF
                CVX=(XPO-XG(J))/RRR
                CVY=(YPO-YMJJJ)/RRR
                VSX1(J,JJ)=VR1*CVX
                VSX2(J,JJ)=VR2*CVX
                VSY1(J,JJ)=VR1*CVY
                VSY2(J,JJ)=VR2*CVY
                VSZ1(J,JJ)=VZ1
                VSZ2(J,JJ)=VZ2
            ELSE
                VSX1(J,JJ)=0.
                VSX2(J,JJ)=0.
                VSY1(J,JJ)=0.
                VSY2(J,JJ)=0.
                VSZ1(J,JJ)=VZ1
                VSZ2(J,JJ)=VZ2
            ENDIF
        END DO

        IF(NSYMY.EQ.1)THEN
            AKAIR=AK0*AIRE(J)
            ADPI2=AKAIR/DPI2
            ADPI=AKAIR/DPI
            SolverVar%SM1=SolverVar%FSM-(FS1(J,1)-FS1(J,2))*ADPI2
            SolverVar%SP1=SolverVar%FSP-(FS1(J,1)+FS1(J,2))*ADPI2
            SolverVar%SM2=-(FS2(J,1)-FS2(J,2))*ADPI
            SolverVar%SP2=-(FS2(J,1)+FS2(J,2))*ADPI
            AKDPI2=ADPI2*AK0
            AKDPI=ADPI*AK0
            SolverVar%VSXP1=SolverVar%VSXP-(VSX1(J,1)+VSX1(J,2))*AKDPI2
            SolverVar%VSXM1=SolverVar%VSXM-(VSX1(J,1)-VSX1(J,2))*AKDPI2
            SolverVar%VSYP1=SolverVar%VSYP-(VSY1(J,1)+VSY1(J,2))*AKDPI2
            SolverVar%VSYM1=SolverVar%VSYM-(VSY1(J,1)-VSY1(J,2))*AKDPI2
            SolverVar%VSZP1=SolverVar%VSZP-(VSZ1(J,1)+VSZ1(J,2))*AKDPI2
            SolverVar%VSZM1=SolverVar%VSZM-(VSZ1(J,1)-VSZ1(J,2))*AKDPI2
            SolverVar%VSXP2=-(VSX2(J,1)+VSX2(J,2))*AKDPI
            SolverVar%VSXM2=-(VSX2(J,1)-VSX2(J,2))*AKDPI
            SolverVar%VSYP2=-(VSY2(J,1)+VSY2(J,2))*AKDPI
            SolverVar%VSYM2=-(VSY2(J,1)-VSY2(J,2))*AKDPI
            SolverVar%VSZP2=-(VSZ2(J,1)+VSZ2(J,2))*AKDPI
            SolverVar%VSZM2=-(VSZ2(J,1)-VSZ2(J,2))*AKDPI
        ELSE
            AKAIR=AK0*AIRE(J)
            ADPI2=AKAIR/DPI2
            ADPI=AKAIR/DPI
            SolverVar%SP1=FSP-FS1(J,1)*ADPI2
            SolverVar%SM1=SP1
            SolverVar%SP2=-FS2(J,1)*ADPI
            SolverVar%SM2=SP2
            AKDPI2=ADPI2*AK0
            AKDPI=ADPI*AK0
            SolverVar%VSXP1=SolverVar%VSXP-VSX1(J,1)*AKDPI2
            SolverVar%VSXM1=VSXP1
            SolverVar%VSYP1=SolverVar%VSYP-VSY1(J,1)*AKDPI2
            SolverVar%VSYM1=VSYP1
            SolverVar%VSZP1=SolverVar%VSZP-VSZ1(J,1)*AKDPI2
            SolverVar%VSZM1=SolverVar%VSZP1
            VSXP2=-VSX2(J,1)*AKDPI
            SolverVar%VSXM2=VSXP2
            SolverVar%VSYP2=-VSY2(J,1)*AKDPI
            SolverVar%VSYM2=VSYP2
            SolverVar%VSZP2=-VSZ2(J,1)*AKDPI
            SolverVar%VSZM2=SolverVar%VSZP2

            ! It is assumed VVV has been run with deriv == 2 also
            IF(deriv == 2) THEN

                SolverVar%VSXP1 = SolverVar%VSXP + VSX1(J,1)*AKDPI2
                SolverVar%VSXM1=VSXP1

                SolverVar%VSYP1 = SolverVar%VSYP + VSY1(J,1)*AKDPI2
                SolverVar%VSYM1=VSYP1

                SolverVar%VSZP1=SolverVar%VSZP-VSZ1(J,1)*AKDPI2
                SolverVar%VSZM1=SolverVar%VSZP1

                VSXP2 = -VSXP2
                SolverVar%VSXM2=VSXP2

                SolverVar%VSYM2 = -SolverVar%VSYP2

                SolverVar%VSZP2 = SolverVar%VSZP2
                SolverVar%VSZM2=SolverVar%VSZP2

            END IF
        ENDIF
        RETURN
    END SUBROUTINE
    !-------------------------------------------------------
    SUBROUTINE VNVF(deriv, AM0,AMH,NEXP,J,XPO,YPO,ZPO,SolverVar)

        INTEGER:: deriv ! 1 for computing the derivative with respect to source point, 2 for field point
        ! It is only needed and supported currently when there is no symmetry around OxZ

        REAL:: AM0,XPO,YPO,ZPO
        REAL:: FS1(NFA,2),FS2(NFA,2)
        INTEGER::J,JJ,NJJ,NEXP,NEXP1
        INTEGER::KK(5),BX,KE,KI,KJ1,KJ2,KJ3,KJ4,L
        REAL::H,A,AKH,AMH,COE3,COE4,EPS
        REAL::PI,PI4,DPI,QPI,TR,WR,WH
        REAL:: VSX1(NFA,2),VSY1(NFA,2),VSZ1(NFA,2)
        REAL:: VSX2(NFA,2),VSY2(NFA,2),VSZ2(NFA,2)

        REAL:: ACT,AKP4,AKR,AKZ1,AKZ2,AKZ3,AKZ4,AQT,ASRO1,ASRO2
        REAL:: ASRO3,ASRO4,C1V3,C2V3,COF1,COF2,COF3,COF4
        REAL:: CSK,CVX,CVY,DD1,DD2,DD3,DD4,DSK
        REAL:: EPZ1,EPZ2,EPZ3,EPZ4,F1,F2,F3,FTS1,FTS2,FTS3,FTS4
        REAL:: PD1X1,PD1X2,PD1X3,PD1X4,PD1Z1,PD1Z2, PD1Z3,PD1Z4,PD2X1,PD2X2
        REAL:: PD2X3,PD2X4,PD2Z1,PD2Z2,PD2Z3,PD2Z4
        REAL:: PSK,PSR1,PSR2,PSR3,PSR4,PSURR1,PSURR2,PSURR3,PSURR4,QJJJ,QTQQ
        REAL:: RO1,RO2,RO3,RO4,RRR,RR1,RR2,RR3,RR4,SCDS,SSDS,STSS
        REAL:: SQ,SIK,SCK,VR21,VR22,VR23,VR24
        REAL:: VXS1,VXS2,VXS3,VXS4,VZ11,VZ12,VZ13,VZ14,VZ21,VZ22,VZ23,VZ24
        REAL:: VYS1,VYS2,VYS3,VYS4,VZS1,VZS2,VZS3,VZS4
        REAL:: XL1,XL2,XL3,XPG,YPG,YMJJJ,ZL11,ZL12,ZL13,ZL14
        REAL:: ZL21,ZL22,ZL23,ZL24,ZL31,ZL32,ZL33,ZL34,ZPG1,ZPG2,ZPG3,ZPG4
        REAL:: ZZZ1,ZZZ2,ZZZ3,ZZZ4,XL(5),YL(5),ZL(5)
        TYPE(TempVar), TARGET :: SolverVar
REAL, POINTER :: T
COMPLEX, DIMENSION(:), POINTER :: ZPB,ZPS
COMPLEX, DIMENSION(:), POINTER :: ZIGB,ZIGS
COMPLEX, DIMENSION(:, :), POINTER :: ZIJ
REAL, POINTER :: FSP,FSM,VSXP,VSYP,VSZP,VSXM,VSYM,VSZM
REAL, POINTER :: SP1,SM1,SP2,SM2
REAL, POINTER :: VSXP1,VSXP2,VSYP1,VSYP2,VSZP1,VSZP2
REAL, POINTER :: VSXM1,VSXM2,VSYM1,VSYM2,VSZM1,VSZM2
INTEGER, POINTER:: NQ
REAL, POINTER:: CQ(:),QQ(:),AMBDA(:),AR(:)
T => SolverVar%T
ZPB => SolverVar%ZPB
ZPS => SolverVar%ZPS
ZIGB => SolverVar%ZIGB
ZIGS => SolverVar%ZIGS
ZIJ => SolverVar%ZIJ
FSP => SolverVar%FSP
FSM => SolverVar%FSM
VSXP => SolverVar%VSXP
VSYP => SolverVar%VSYP
VSZP => SolverVar%VSZP
VSXM => SolverVar%VSXM
VSYM => SolverVar%VSYM
VSZM => SolverVar%VSZM
SP1 => SolverVar%SP1
SM1 => SolverVar%SM1
SP2 => SolverVar%SP2
SM2 => SolverVar%SM2
VSXP1 => SolverVar%VSXP1
VSXP2 => SolverVar%VSXP2
VSYP1 => SolverVar%VSYP1
VSYP2 => SolverVar%VSYP2
VSZP1 => SolverVar%VSZP1
VSZP2 => SolverVar%VSZP2
VSXM1 => SolverVar%VSXM1
VSXM2 => SolverVar%VSXM2
VSYM1 => SolverVar%VSYM1
VSYM2 => SolverVar%VSYM2
VSZM1 => SolverVar%VSZM1
VSZM2 => SolverVar%VSZM2
NQ => SolverVar%NQ
CQ => SolverVar%CQ
QQ => SolverVar%QQ
AMBDA => SolverVar%AMBDA
AR => SolverVar%AR
   
        PI4=ATAN(1.)
        PI=4.*ATAN(1.)
        DPI=2.*PI
        QPI=4.*PI
        H=Depth
        WH=DPI/T
        AKH=AMH*TANH(AMH)
        WR=WH
        TR=DPI/WR
        NJJ=NSYMY+1
        !       IF(AMH-AKH-1.E-03)7106,7106,7101
        !  7106 WRITE(*,7102)
        !  7102 FORMAT(/5X,'PROFONDEUR QUASI-INFINIE'/5X,
        !      1'LE PROGRAMME EN PROFONDEUR INFINIE SERAIT PLUS ADAPTE')
        !       GOTO 7104
        !  7101 IF(AKH-0.1)7103,7103,7104
        !  7103 WRITE(LE,7105)
        !  7105 FORMAT(/5X,'PROFONDEUR TROP FAIBLE POUR LA LONGUEUR D''ONDE')
        !  7104 CONTINUE

        !       CALL LISV(AKH,AMH,AMBDA,AR,NEXP)
        !       ENDIF

        !    AR=0.
        !    NEXP=0
        !    AMBDA=0.

        EPS=0.0001
        A=(AMH+AKH)**2/(H*(AMH**2-AKH**2+AKH))
        NEXP1=NEXP+1
        SolverVar%AMBDA(NEXP1)=0.
        SolverVar%AR(NEXP1)=2.
        COE3=-1./(8.*PI**2)
        COE4=-A/(8.*PI)
        !       print*,'A',A,AMH,AKH,NEXP
        !       read*
        DO JJ=1,NJJ
            BX=(-1)**(JJ+1)
            !       DO 21 J=1,IMX
            QJJJ=BX*YN(J)
            YMJJJ=BX*YG(J)
            COF1=A*COE3*AIRE(J)
            COF2=COE4*AIRE(J)
            COF3=AM0*COF1
            COF4=AM0*COF2
            RRR=SQRT((XPO-XG(J))**2+(YPO-YMJJJ)**2)
            AKR=AM0*RRR
            ZZZ1=ZPO+ZG(J)
            AKZ1=AM0*ZZZ1
            DD1=SQRT(RRR**2+ZZZ1**2)
            !                   print*,'ZZ',ZZZ1,DD1
            !       read*
            IF(DD1.GT.EPS)THEN
                RR1=AM0*DD1
                PSR1=PI/RR1
                PSURR1=PI/RR1**3
            ELSE
                PSR1=0.
                PSURR1=0.
            ENDIF
            IF(AKZ1.GT.-1.5E-6)THEN
                !WRITE(*,*)'AKZ < -1.5 E-6'
                !STOP Bug Fixes
                AKZ1 = AKZ1 + 0
            ELSE
                IF(AKZ1.GT.-16.)THEN
                    IF(AKR.LT.99.7)THEN
                        IF(AKZ1.LT.-1.E-2)THEN
                            KJ1=INT(8*(ALOG10(-AKZ1)+4.5))
                        ELSE
                            KJ1=INT(5*(ALOG10(-AKZ1)+6))
                        ENDIF
                        KJ1=MAX(KJ1,2)
                        KJ1=MIN(KJ1,TABULATION_JZ-1)
                        IF(AKR.LT.1.)THEN
                            KI=INT(5*(ALOG10(AKR+1.E-20)+6)+1)
                        ELSE
                            KI=INT(3*AKR+28)
                        ENDIF
                        KI=MAX(KI,2)
                        KI=MIN(KI,TABULATION_IR-1)
                        XL1=PL2(XR(KI),XR(KI+1),XR(KI-1),AKR)
                        XL2=PL2(XR(KI+1),XR(KI-1),XR(KI),AKR)
                        XL3=PL2(XR(KI-1),XR(KI),XR(KI+1),AKR)
                        ZL11=PL2(XZ(KJ1),XZ(KJ1+1),XZ(KJ1-1),AKZ1)
                        ZL21=PL2(XZ(KJ1+1),XZ(KJ1-1),XZ(KJ1),AKZ1)
                        ZL31=PL2(XZ(KJ1-1),XZ(KJ1),XZ(KJ1+1),AKZ1)
                        F1=XL1*APD1Z(KI-1,KJ1-1)+XL2*APD1Z(KI,KJ1-1)+XL3*APD1Z(KI+1,KJ1-1)
                        F2=XL1*APD1Z(KI-1,KJ1)+XL2*APD1Z(KI,KJ1)+XL3*APD1Z(KI+1,KJ1)
                        F3=XL1*APD1Z(KI-1,KJ1+1)+XL2*APD1Z(KI,KJ1+1)+XL3*APD1Z(KI+1,KJ1+1)
                        PD1Z1=ZL11*F1+ZL21*F2+ZL31*F3
                        F1=XL1*APD2Z(KI-1,KJ1-1)+XL2*APD2Z(KI,KJ1-1)+XL3*APD2Z(KI+1,KJ1-1)
                        F2=XL1*APD2Z(KI-1,KJ1)+XL2*APD2Z(KI,KJ1)+XL3*APD2Z(KI+1,KJ1)
                        F3=XL1*APD2Z(KI-1,KJ1+1)+XL2*APD2Z(KI,KJ1+1)+XL3*APD2Z(KI+1,KJ1+1)
                        PD2Z1=ZL11*F1+ZL21*F2+ZL31*F3
                    ELSE
                        EPZ1=EXP(AKZ1)
                        AKP4=AKR-PI4
                        SQ=SQRT(DPI/AKR)
                        CSK=COS(AKP4)
                        SIK=SIN(AKP4)
                        PSK=PI*SQ*SIK
                        SCK=SQ*CSK
                        PD1Z1=PSURR1*AKZ1-PSK*EPZ1
                        PD2Z1=EPZ1*SCK
                    ENDIF
                    VZ11=PD1Z1-PSURR1*AKZ1
                    VZ21=PD2Z1
                ELSE
                    PD1Z1=PSURR1*AKZ1
                    PD2Z1=0.
                    VZ11=0.
                    VZ21=0.
                ENDIF
            ENDIF
            ZZZ2=ZG(J)-ZPO-2*H
            AKZ2=AM0*ZZZ2
            DD2=SQRT(RRR**2+ZZZ2**2)
            IF(DD2.GT.EPS)THEN
                RR2=AM0*DD2
                PSR2=PI/RR2
                PSURR2=PI/RR2**3
            ELSE
                PSR2=0.
                PSURR2=0.
            ENDIF
            IF(AKZ2.GT.-1.5E-6)THEN
                !WRITE(*,*)'AKZ < -1.5 E-6'
                !STOP Bug Fixes
                AKZ2 = AKZ2 + 0
            ELSE
                IF(AKZ2.GT.-16.)THEN
                    IF(AKR.LT.99.7)THEN
                        IF(AKZ2.LT.-1.E-2)THEN
                            KJ2=INT(8*(ALOG10(-AKZ2)+4.5))
                        ELSE
                            KJ2=INT(5*(ALOG10(-AKZ2)+6))
                        ENDIF
                        KJ2=MAX(KJ2,2)
                        KJ2=MIN(KJ2,45)
                        ZL12=PL2(XZ(KJ2),XZ(KJ2+1),XZ(KJ2-1),AKZ2)
                        ZL22=PL2(XZ(KJ2+1),XZ(KJ2-1),XZ(KJ2),AKZ2)
                        ZL32=PL2(XZ(KJ2-1),XZ(KJ2),XZ(KJ2+1),AKZ2)
                        F1=XL1*APD1Z(KI-1,KJ2-1)+XL2*APD1Z(KI,KJ2-1)+XL3*APD1Z(KI+1,KJ2-1)
                        F2=XL1*APD1Z(KI-1,KJ2)+XL2*APD1Z(KI,KJ2)+XL3*APD1Z(KI+1,KJ2)
                        F3=XL1*APD1Z(KI-1,KJ2+1)+XL2*APD1Z(KI,KJ2+1)+XL3*APD1Z(KI+1,KJ2+1)
                        PD1Z2=ZL12*F1+ZL22*F2+ZL32*F3
                        F1=XL1*APD2Z(KI-1,KJ2-1)+XL2*APD2Z(KI,KJ2-1)+XL3*APD2Z(KI+1,KJ2-1)
                        F2=XL1*APD2Z(KI-1,KJ2)+XL2*APD2Z(KI,KJ2)+XL3*APD2Z(KI+1,KJ2)
                        F3=XL1*APD2Z(KI-1,KJ2+1)+XL2*APD2Z(KI,KJ2+1)+XL3*APD2Z(KI+1,KJ2+1)
                        PD2Z2=ZL12*F1+ZL22*F2+ZL32*F3
                    ELSE
                        EPZ2=EXP(AKZ2)
                        PD1Z2=PSURR2*AKZ2-PSK*EPZ2
                        PD2Z2=EPZ2*SCK
                    ENDIF
                    VZ12=PD1Z2-PSURR2*AKZ2
                    VZ22=PD2Z2
                ELSE
                    PD1Z2=PSURR2*AKZ2
                    PD2Z2=0.
                    VZ12=0.
                    VZ22=0.
                ENDIF
            ENDIF
            ZZZ3=ZPO-ZG(J)-2*H
            AKZ3=AM0*ZZZ3
            DD3=SQRT(RRR**2+ZZZ3**2)
            IF(DD3.GT.EPS)THEN
                RR3=AM0*DD3
                PSR3=PI/RR3
                PSURR3=PI/RR3**3
            ELSE
                PSR3=0.
                PSURR3=0.
            ENDIF
            IF(AKZ3.GT.-1.5E-6)THEN
                !WRITE(*,*)'AKZ < -1.5 E-6'
                !STOP Bug Fixes
                AKZ3 = AKZ3 + 0
            ELSE
                IF(AKZ3.GT.-16.)THEN
                    IF(AKR.LT.99.7)THEN
                        IF(AKZ3.LT.-1.E-2)THEN
                            KJ3=INT(8*(ALOG10(-AKZ3)+4.5))
                        ELSE
                            KJ3=INT(5*(ALOG10(-AKZ3)+6))
                        ENDIF
                        KJ3=MAX(KJ3,2)
                        KJ3=MIN(KJ3,45)
                        ZL13=PL2(XZ(KJ3),XZ(KJ3+1),XZ(KJ3-1),AKZ3)
                        ZL23=PL2(XZ(KJ3+1),XZ(KJ3-1),XZ(KJ3),AKZ3)
                        ZL33=PL2(XZ(KJ3-1),XZ(KJ3),XZ(KJ3+1),AKZ3)
                        F1=XL1*APD1Z(KI-1,KJ3-1)+XL2*APD1Z(KI,KJ3-1)+XL3*APD1Z(KI+1,KJ3-1)
                        F2=XL1*APD1Z(KI-1,KJ3)+XL2*APD1Z(KI,KJ3)+XL3*APD1Z(KI+1,KJ3)
                        F3=XL1*APD1Z(KI-1,KJ3+1)+XL2*APD1Z(KI,KJ3+1)+XL3*APD1Z(KI+1,KJ3+1)
                        PD1Z3=ZL13*F1+ZL23*F2+ZL33*F3
                        F1=XL1*APD2Z(KI-1,KJ3-1)+XL2*APD2Z(KI,KJ3-1)+XL3*APD2Z(KI+1,KJ3-1)
                        F2=XL1*APD2Z(KI-1,KJ3)+XL2*APD2Z(KI,KJ3)+XL3*APD2Z(KI+1,KJ3)
                        F3=XL1*APD2Z(KI-1,KJ3+1)+XL2*APD2Z(KI,KJ3+1)+XL3*APD2Z(KI+1,KJ3+1)
                        PD2Z3=ZL13*F1+ZL23*F2+ZL33*F3
                    ELSE
                        EPZ3=EXP(AKZ3)
                        PD1Z3=PSURR3*AKZ3-PSK*EPZ3
                        PD2Z3=EPZ3*SCK
                    ENDIF
                    VZ13=PD1Z3-PSURR3*AKZ3
                    VZ23=PD2Z3
                ELSE
                    PD1Z3=PSURR3*AKZ3
                    PD2Z3=0.
                    VZ13=0.
                    VZ23=0.
                ENDIF
            ENDIF
            ZZZ4=-ZG(J)-ZPO-4*H
            AKZ4=AM0*ZZZ4
            DD4=SQRT(RRR**2+ZZZ4**2)
            IF(DD4.GT.EPS)THEN
                RR4=AM0*DD4
                PSR4=PI/RR4
                PSURR4=PI/RR4**3
            ELSE
                PSR4=0.
                PSURR4=0.
            ENDIF
            IF(AKZ4.GT.-1.5E-6)THEN
                !WRITE(*,*)'AKZ < -1.5 E-6'
                !STOP Bug Fixes
                AKZ4 = AKZ4 + 0
            ELSE
                IF(AKZ4.GT.-16.)THEN
                    IF(AKR.LT.99.7)THEN
                        IF(AKZ4.LT.-1.E-2)THEN
                            KJ4=INT(8*(ALOG10(-AKZ4)+4.5))
                        ELSE
                            KJ4=INT(5*(ALOG10(-AKZ4)+6))
                        ENDIF
                        KJ4=MAX(KJ4,2)
                        KJ4=MIN(KJ4,45)
                        ZL14=PL2(XZ(KJ4),XZ(KJ4+1),XZ(KJ4-1),AKZ4)
                        ZL24=PL2(XZ(KJ4+1),XZ(KJ4-1),XZ(KJ4),AKZ4)
                        ZL34=PL2(XZ(KJ4-1),XZ(KJ4),XZ(KJ4+1),AKZ4)
                        F1=XL1*APD1Z(KI-1,KJ4-1)+XL2*APD1Z(KI,KJ4-1)+XL3*APD1Z(KI+1,KJ4-1)
                        F2=XL1*APD1Z(KI-1,KJ4)+XL2*APD1Z(KI,KJ4)+XL3*APD1Z(KI+1,KJ4)
                        F3=XL1*APD1Z(KI-1,KJ4+1)+XL2*APD1Z(KI,KJ4+1)+XL3*APD1Z(KI+1,KJ4+1)
                        PD1Z4=ZL14*F1+ZL24*F2+ZL34*F3
                        F1=XL1*APD2Z(KI-1,KJ4-1)+XL2*APD2Z(KI,KJ4-1)+XL3*APD2Z(KI+1,KJ4-1)
                        F2=XL1*APD2Z(KI-1,KJ4)+XL2*APD2Z(KI,KJ4)+XL3*APD2Z(KI+1,KJ4)
                        F3=XL1*APD2Z(KI-1,KJ4+1)+XL2*APD2Z(KI,KJ4+1)+XL3*APD2Z(KI+1,KJ4+1)
                        PD2Z4=ZL14*F1+ZL24*F2+ZL34*F3
                    ELSE
                        EPZ4=EXP(AKZ4)
                        PD1Z4=PSURR4*AKZ4-PSK*EPZ4
                        PD2Z4=EPZ4*SCK
                    ENDIF
                    VZ14=PD1Z4-PSURR4*AKZ4
                    VZ24=PD2Z4
                ELSE
                    PD1Z4=PSURR4*AKZ4
                    PD2Z4=0.
                    VZ14=0.
                    VZ24=0.
                ENDIF
            ENDIF
            QTQQ=PD1Z1+PD1Z2+PD1Z3+PD1Z4
            FS1(J,JJ)=COF1*(QTQQ-PSR1-PSR2-PSR3-PSR4)
            STSS=PD2Z1+PD2Z2+PD2Z3+PD2Z4
            FS2(J,JJ)=COF2*STSS
            IF(RRR.GT.EPS)THEN
                IF(AKZ1.LE.-1.5E-6)THEN
                    IF(AKZ1.GT.-16.)THEN
                        IF(AKR.LT.99.7)THEN
                            F1=XL1*APD1X(KI-1,KJ1-1)+XL2*APD1X(KI,KJ1-1)+XL3*APD1X(KI+1,KJ1-1)
                            F2=XL1*APD1X(KI-1,KJ1)+XL2*APD1X(KI,KJ1)+XL3*APD1X(KI+1,KJ1)
                            F3=XL1*APD1X(KI-1,KJ1+1)+XL2*APD1X(KI,KJ1+1)+XL3*APD1X(KI+1,KJ1+1)
                            PD1X1=ZL11*F1+ZL21*F2+ZL31*F3
                            F1=XL1*APD2X(KI-1,KJ1-1)+XL2*APD2X(KI,KJ1-1)+XL3*APD2X(KI+1,KJ1-1)
                            F2=XL1*APD2X(KI-1,KJ1)+XL2*APD2X(KI,KJ1)+XL3*APD2X(KI+1,KJ1)
                            F3=XL1*APD2X(KI-1,KJ1+1)+XL2*APD2X(KI,KJ1+1)+XL3*APD2X(KI+1,KJ1+1)
                            PD2X1=ZL11*F1+ZL21*F2+ZL31*F3
                        ELSE
                            DSK=0.5/AKR
                            SCDS=PI*SQ*(CSK-DSK*SIK)
                            SSDS=SQ*(SIK+DSK*CSK)
                            PD1X1=-PSURR1*AKR-EPZ1*SCDS
                            PD2X1=EPZ1*SSDS
                        ENDIF
                        VR21=-PD2X1
                    ELSE
                        PD1X1=-PSURR1*AKR
                        PD2X1=0.
                        VR21=0.
                    ENDIF
                    IF(AKZ2.LE.-1.5E-6)THEN
                        IF(AKZ2.GT.-16.)THEN
                            IF(AKR.LT.99.7)THEN
                                F1=XL1*APD1X(KI-1,KJ2-1)+XL2*APD1X(KI,KJ2-1)+XL3*APD1X(KI+1,KJ2-1)
                                F2=XL1*APD1X(KI-1,KJ2)+XL2*APD1X(KI,KJ2)+XL3*APD1X(KI+1,KJ2)
                                F3=XL1*APD1X(KI-1,KJ2+1)+XL2*APD1X(KI,KJ2+1)+XL3*APD1X(KI+1,KJ2+1)
                                PD1X2=ZL12*F1+ZL22*F2+ZL32*F3
                                F1=XL1*APD2X(KI-1,KJ2-1)+XL2*APD2X(KI,KJ2-1)+XL3*APD2X(KI+1,KJ2-1)
                                F2=XL1*APD2X(KI-1,KJ2)+XL2*APD2X(KI,KJ2)+XL3*APD2X(KI+1,KJ2)
                                F3=XL1*APD2X(KI-1,KJ2+1)+XL2*APD2X(KI,KJ2+1)+XL3*APD2X(KI+1,KJ2+1)
                                PD2X2=ZL12*F1+ZL22*F2+ZL32*F3
                            ELSE
                                PD1X2=-PSURR2*AKR-EPZ2*SCDS
                                PD2X2=EPZ2*SSDS
                            ENDIF
                            VR22=-PD2X2
                        ELSE
                            PD1X2=-PSURR2*AKR
                            PD2X2=0.
                            VR22=0.
                        ENDIF
                    ENDIF
                    IF(AKZ3.LE.-1.5E-6)THEN
                        IF(AKZ3.GT.-16.)THEN
                            IF(AKR.LT.99.7)THEN
                                F1=XL1*APD1X(KI-1,KJ3-1)+XL2*APD1X(KI,KJ3-1)+XL3*APD1X(KI+1,KJ3-1)
                                F2=XL1*APD1X(KI-1,KJ3)+XL2*APD1X(KI,KJ3)+XL3*APD1X(KI+1,KJ3)
                                F3=XL1*APD1X(KI-1,KJ3+1)+XL2*APD1X(KI,KJ3+1)+XL3*APD1X(KI+1,KJ3+1)
                                PD1X3=ZL13*F1+ZL23*F2+ZL33*F3
                                F1=XL1*APD2X(KI-1,KJ3-1)+XL2*APD2X(KI,KJ3-1)+XL3*APD2X(KI+1,KJ3-1)
                                F2=XL1*APD2X(KI-1,KJ3)+XL2*APD2X(KI,KJ3)+XL3*APD2X(KI+1,KJ3)
                                F3=XL1*APD2X(KI-1,KJ3+1)+XL2*APD2X(KI,KJ3+1)+XL3*APD2X(KI+1,KJ3+1)
                                PD2X3=ZL13*F1+ZL23*F2+ZL33*F3
                            ELSE
                                PD1X3=-PSURR3*AKR-EPZ3*SCDS
                                PD2X3=EPZ3*SSDS
                            ENDIF
                            VR23=-PD2X3
                        ELSE
                            PD1X3=-PSURR3*AKR
                            PD2X3=0.
                            VR23=0.
                        ENDIF
                    ENDIF
                    IF(AKZ4.LE.-1.5E-6)THEN
                        IF(AKZ4.GT.-16.)THEN
                            IF(AKR.LT.99.7)THEN
                                F1=XL1*APD1X(KI-1,KJ4-1)+XL2*APD1X(KI,KJ4-1)+XL3*APD1X(KI+1,KJ4-1)
                                F2=XL1*APD1X(KI-1,KJ4)+XL2*APD1X(KI,KJ4)+XL3*APD1X(KI+1,KJ4)
                                F3=XL1*APD1X(KI-1,KJ4+1)+XL2*APD1X(KI,KJ4+1)+XL3*APD1X(KI+1,KJ4+1)
                                PD1X4=ZL14*F1+ZL24*F2+ZL34*F3
                                F1=XL1*APD2X(KI-1,KJ4-1)+XL2*APD2X(KI,KJ4-1)+XL3*APD2X(KI+1,KJ4-1)
                                F2=XL1*APD2X(KI-1,KJ4)+XL2*APD2X(KI,KJ4)+XL3*APD2X(KI+1,KJ4)
                                F3=XL1*APD2X(KI-1,KJ4+1)+XL2*APD2X(KI,KJ4+1)+XL3*APD2X(KI+1,KJ4+1)
                                PD2X4=ZL14*F1+ZL24*F2+ZL34*F3
                            ELSE
                                PD1X4=-PSURR4*AKR-EPZ4*SCDS
                                PD2X4=EPZ4*SSDS
                            ENDIF
                            VR24=-PD2X4
                        ELSE
                            PD1X4=-PSURR4*AKR
                            PD2X4=0.
                            VR24=0.
                        ENDIF
                    ENDIF
                    C1V3=-COF3*(PD1X1+PD1X2+PD1X3+PD1X4)
                    C2V3=COF4*(VR21+VR22+VR23+VR24)
                    CVX=(XPO-XG(J))/RRR
                    CVY=(YPO-YMJJJ)/RRR
                    VSX1(J,JJ)=C1V3*CVX
                    VSX2(J,JJ)=C2V3*CVX
                    VSY1(J,JJ)=C1V3*CVY
                    VSY2(J,JJ)=C2V3*CVY
                ELSE
                    VSX1(J,JJ)=0.
                    VSX2(J,JJ)=0.
                    VSY1(J,JJ)=0.
                    VSY2(J,JJ)=0.
                ENDIF
                VSZ1(J,JJ)=COF3*(PD1Z1-PD1Z2+PD1Z3-PD1Z4)
                VSZ2(J,JJ)=COF4*(VZ21-VZ22+VZ23-VZ24)
            ENDIF
            XPG=XPO-XG(J)
            YPG=YPO-YMJJJ
            ACT=-0.5*AIRE(J)/QPI
            DO KE=1,NEXP1
                AQT=ACT*AR(KE)
                ZPG1=ZPO-2.*H+H*AMBDA(KE)-ZG(J)
                ZPG2=-ZPO-H*AMBDA(KE)-ZG(J)
                ZPG3=-ZPO-4.*H+H*AMBDA(KE)-ZG(J)
                ZPG4=ZPO+2.*H-H*AMBDA(KE)-ZG(J)
                RR1=RRR**2+ZPG1**2
                RO1=SQRT(RR1)
                IF(RO1.GT.EPS)THEN
                    FTS1=AQT/RO1
                    ASRO1=FTS1/RR1
                ELSE
                    FTS1=0.
                    ASRO1=0.
                ENDIF
                VXS1=-XPG*ASRO1
                VYS1=-YPG*ASRO1
                VZS1=-ZPG1*ASRO1
                IF(KE.EQ.NEXP1)THEN
                    KK(1)=M1(J)
                    KK(2)=M2(J)
                    KK(3)=M3(J)
                    KK(4)=M4(J)
                    KK(5)=KK(1)
                    DO L=1,5
                        XL(L)=X(KK(L))
                        YL(L)=Y(KK(L))
                        ZL(L)=Z(KK(L))
                    END DO

                    CALL VVG(XL,YL,ZL,JJ,XN(J),YN(J),ZN(J),AIRE(J),TDIS(J),&
                        XG(J),YG(J),ZG(J),XPO,YPO,-ZPO,FTS2,VXS2,VYS2,VZS2)

                ELSE
                    RR2=RRR**2+ZPG2**2
                    RO2=SQRT(RR2)
                    IF(RO2.GT.EPS)THEN
                        FTS2=AQT/RO2
                        ASRO2=FTS2/RR2
                    ELSE
                        FTS2=0.
                        ASRO2=0.
                    ENDIF
                    VXS2=-XPG*ASRO2
                    VYS2=-YPG*ASRO2
                    VZS2=-ZPG2*ASRO2
                ENDIF
                RR3=RRR**2+ZPG3**2
                RO3=SQRT(RR3)
                IF(RO3.GT.EPS)THEN
                    FTS3=AQT/RO3
                    ASRO3=FTS3/RR3
                ELSE
                    FTS3=0.
                    ASRO3=0.
                ENDIF
                VXS3=-XPG*ASRO3
                VYS3=-YPG*ASRO3
                VZS3=-ZPG3*ASRO3
                RR4=RRR**2+ZPG4**2
                RO4=SQRT(RR4)
                IF(RO4.GT.EPS)THEN
                    FTS4=AQT/RO4
                    ASRO4=FTS4/RR4
                ELSE
                    FTS4=0.
                    ASRO4=0.
                ENDIF
                VXS4=-XPG*ASRO4
                VYS4=-YPG*ASRO4
                VZS4=-ZPG4*ASRO4
                FS1(J,JJ)=FS1(J,JJ)+FTS1+FTS2+FTS3+FTS4
                VSX1(J,JJ)=VSX1(J,JJ)+(VXS1+VXS2+VXS3+VXS4)
                VSY1(J,JJ)=VSY1(J,JJ)+(VYS1+VYS2+VYS3+VYS4)
                VSZ1(J,JJ)=VSZ1(J,JJ)+(VZS1-VZS2-VZS3+VZS4)
            END DO
        !    21 CONTINUE
        END DO
        IF(NSYMY.EQ.1)THEN
            !       DO 481 J=1,IMX
            SM1=FSM+FS1(J,1)-FS1(J,2)
            SP1=FSP+FS1(J,1)+FS1(J,2)
            SM2=FS2(J,1)-FS2(J,2)
            SP2=FS2(J,1)+FS2(J,2)
            VSXP1=VSXP+VSX1(J,1)+VSX1(J,2)
            VSXM1=VSXM+VSX1(J,1)-VSX1(J,2)
            VSYP1=VSYP+VSY1(J,1)+VSY1(J,2)
            VSYM1=VSYM+VSY1(J,1)-VSY1(J,2)
            SolverVar%VSZP1=SolverVar%VSZP+VSZ1(J,1)+VSZ1(J,2)
            SolverVar%VSZM1=SolverVar%VSZM+VSZ1(J,1)-VSZ1(J,2)
            VSXP2=VSX2(J,1)+VSX2(J,2)
            VSXM2=VSX2(J,1)-VSX2(J,2)
            VSYP2=VSY2(J,1)+VSY2(J,2)
            VSYM2=VSY2(J,1)-VSY2(J,2)
            SolverVar%VSZP2=VSZ2(J,1)+VSZ2(J,2)
            SolverVar%VSZM2=VSZ2(J,1)-VSZ2(J,2)
        !   481 CONTINUE
        ELSE
            !       DO 491 J=1,IMX
            SP1=FSP+FS1(J,1)
            SM1=SP1
            SP2=FS2(J,1)
            SM2=SP2
            VSXP1=VSXP+VSX1(J,1)
            VSXM1=VSXP1
            VSYP1=VSYP+VSY1(J,1)
            VSYM1=VSYP1
            VSZP1=VSZP+VSZ1(J,1)
            VSZM1=VSZP1
            VSXP2=VSX2(J,1)
            VSXM2=VSXP2
            VSYP2=VSY2(J,1)
            VSYM2=VSYP2
            VSZP2=VSZ2(J,1)
            VSZM2=VSZP2

            ! It is assumed VVV has been run with deriv == 2 also
            IF(deriv == 2) THEN

                VSXP1=VSXP - VSX1(J,1)
                VSXM1=VSXP1

                VSYP1=VSYP-VSY1(J,1)
                VSYM1=VSYP1

                VSZP1=VSZP - VSZ1(J,1)
                VSZM1=VSZP1

                VSXP2=-VSX2(J,1)
                VSXM2=VSXP2

                VSYP2 = -VSY2(J,1)
                VSYM2=VSYP2

                VSZP2 = -VSZ2(J,1)
                VSZM2=VSZP2

            END IF
        !   491 CONTINUE
        ENDIF
        RETURN
    END SUBROUTINE
    !------------------------------------------------------------

    SUBROUTINE VVG(XLL,YLL,ZLL,JJ,PN,QN,RN,ARJ,TDJ,&
        XGG,YGG,ZGG,XPO,YPO,ZPO,FS,VXS,VYS,VZS)

        INTEGER::JJ,MJJ,L
        REAL:: PN,QN,RN,XGG,YGG,ZGG,VXS,VYS,VZS,XPO,YPO,ZPO,FS
        REAL:: XLL(5),YLL(5),ZLL(5),ARJ,TDJ
        REAL:: RR(5),DRX(5),DRY(5),DRZ(5)
        REAL:: DEN,AT,DNL,ANL,ARG,RO,GY,GZ,ASRO,DK,PJ,QJ,RJ,GYX,GYY,GYZ
        REAL:: SGN,DDK,ANT,DNT,ALDEN,ANTX,ANTY,ANTZ,ANLX,ANLY,ANLZ
        REAL:: DR,DS,DNTX,DNTY,DNTZ,DENL,DENT,ATX,ATY,ATZ,DLOGG
        REAL:: DAT,CM

        MJJ=(-1)**(JJ+1)
        RO=SQRT((XPO-XGG)**2+(YPO-YGG*MJJ)**2+(ZPO-ZGG)**2)
        GZ=(XPO-XGG)*PN+(YPO-YGG*MJJ)*QN*MJJ+(ZPO-ZGG)*RN
        IF(RO-7.*TDJ > 0) THEN
            FS=-ARJ/(RO*12.5663706)
            ASRO=FS/RO**2
            VXS=-(XPO-XGG)*ASRO
            VYS=-(YPO-YGG*MJJ)*ASRO
            VZS=-(ZPO-ZGG)*ASRO
            RETURN
        END IF

        DO L=1,5
            RR(L)=SQRT((XPO-XLL(L))**2+(YPO-YLL(L)*MJJ)**2+(ZPO-ZLL(L))**2)
            DRX(L)=(XPO-XLL(L))/RR(L)
            DRY(L)=(YPO-YLL(L)*MJJ)/RR(L)
            DRZ(L)=(ZPO-ZLL(L))/RR(L)
        END DO
        FS=0.
        VXS=0.
        VYS=0.
        VZS=0.
        DO L=1,4
            DK=SQRT((XLL(L+1)-XLL(L))**2+(YLL(L+1)-YLL(L))**2 &
                +(ZLL(L+1)-ZLL(L))**2)

            IF(DK-1.E-3*TDJ > 0) THEN
                PJ=(XLL(L+1)-XLL(L))/DK
                QJ=(YLL(L+1)-YLL(L))/DK*MJJ
                RJ=(ZLL(L+1)-ZLL(L))/DK
                GYX=MJJ*QN*RJ-RN*QJ
                GYY=RN*PJ-PN*RJ
                GYZ=PN*QJ-QN*MJJ*PJ
                GY=(XPO-XLL(L))*GYX+(YPO-YLL(L)*MJJ)*GYY+(ZPO-ZLL(L))*GYZ
                SGN=SIGN(1.,GZ)
                DDK=2.*DK
                ANT=GY*DDK
                DNT=(RR(L+1)+RR(L))**2-DK*DK+2.*ABS(GZ)*(RR(L+1)+RR(L))
                ARG=ANT/DNT
                ANL=RR(L+1)+RR(L)+DK
                DNL=RR(L+1)+RR(L)-DK
                DEN=ANL/DNL
                IF(ABS(GZ).GE.1.E-4*TDJ)THEN
                    AT=ATAN(ARG)
                ELSE
                    AT=0.
                ENDIF
                ALDEN=ALOG(DEN)
                FS=FS+GY*ALDEN-2.*ABS(GZ)*AT
                ANTX=GYX*DDK
                ANTY=GYY*DDK
                ANTZ=GYZ*DDK
                ANLX=DRX(L+1)+DRX(L)
                ANLY=DRY(L+1)+DRY(L)
                ANLZ=DRZ(L+1)+DRZ(L)
                DR=2.*(RR(L+1)+RR(L)+ABS(GZ))
                DS=2.*(RR(L+1)+RR(L))*SGN
                DNTX=DR*ANLX+PN*DS
                DNTY=DR*ANLY+QN*MJJ*DS
                DNTZ=DR*ANLZ+RN*DS
                DENL=ANL*DNL
                DENT=ANT*ANT+DNT*DNT
                ATX=(ANTX*DNT-DNTX*ANT)/DENT
                ATY=(ANTY*DNT-DNTY*ANT)/DENT
                ATZ=(ANTZ*DNT-DNTZ*ANT)/DENT
                DLOGG=(DNL-ANL)/DENL
                DAT=2.*AT*SGN
                VXS=VXS+GYX*ALDEN+GY*ANLX*DLOGG-2.*ABS(GZ)*ATX-DAT*PN
                VYS=VYS+GYY*ALDEN+GY*ANLY*DLOGG-2.*ABS(GZ)*ATY-DAT*QN*MJJ
                VZS=VZS+GYZ*ALDEN+GY*ANLZ*DLOGG-2.*ABS(GZ)*ATZ-DAT*RN
            END IF
        END DO
        CM=-MJJ/12.5663706
        FS=FS*CM
        VXS=VXS*CM
        VYS=VYS*CM
        VZS=VZS*CM
        RETURN
    END SUBROUTINE
    !--------------------------------------------------------------------

    REAL FUNCTION PL2(U1,U2,U3,XU)
        REAL::U1,U2,U3,XU
        PL2=((XU-U1)*(XU-U2))/((U3-U1)*(U3-U2))
        RETURN
    END FUNCTION
!--------------------------------------------------------------------      


END MODULE
