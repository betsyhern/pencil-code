;;;;;;;;;;;;;;;;;;;;;;
;;;   thermo.pro   ;;;
;;;;;;;;;;;;;;;;;;;;;;

;;;
;;;  Author: wd (Wolfgang.Dobler@kis.uni-freiburg.de)
;;;  Date:   25-Feb-2002
;;;
;;;  Description:
;;;   Calculate all relevant thermodynamical variables from lnrho and
;;;   ss.

pp  = exp(gamma*(ss+lnrho))
cs2 = gamma * exp(gamma*ss+gamma1*lnrho)
TT  = cs2/gamma1

;; initial profiles of temperature, density and entropy for solar
;; convection runs
ssinit = (lnrhoinit = (Tinit = 0.*z))

top = where(z ge z2)
Tref = cs0^2/gamma1
lnrhoref = alog(rho0)
ssref = (2*alog(cs0) - gamma1*alog(rho0)-alog(gamma))/gamma
zo = [z2,ztop]
if (isothtop eq 0) then begin   ; polytropic top layer
  beta = gamma/gamma1*gravz/(mpoly2+1)
  if (top[0] ge 0) then begin
    Tinit[top] = Tref + beta*(z[top]-ztop)
    lnrhoinit[top] = lnrhoref + mpoly2*alog(1.+beta*(z[top]-ztop)/Tref)
    ssinit[top] = ssref $
                  + (1-mpoly2*(gamma-1))/gamma $
                    * alog(1.+beta*(z[top]-ztop)/Tref)
    lnrhoref = lnrhoref + mpoly2*alog(1.+beta*(z2-ztop)/Tref)
    ssref = ssref $
            + (1-mpoly2*(gamma-1))/gamma * alog(1.+beta*(z2-ztop)/Tref)
    Tref = Tref + beta*(z2-ztop)
  endif
endif else begin                ; isothermal top layer
  beta = 0.
  if (top[0] ge 0) then begin 
    Tinit[top] = Tref
    lnrhoinit[top] = lnrhoref + gamma/gamma1*gravz*(z[top]-ztop)/Tref
    ssinit[top] = ssref - gravz*(z[top]-ztop)/Tref
    lnrhoref = lnrhoref + gamma/gamma1*gravz*(z2-ztop)/Tref
    ssref = ssref  - gravz*(z2-ztop)/Tref
    Tref = Tref
  endif
endelse
;
stab = where((z le z2) and (z ge z1))
if (stab[0] ge 0) then begin
  beta = gamma/gamma1*gravz/(mpoly0+1)
  Tinit[stab] = Tref + beta*(z[stab]-z2)
  lnrhoinit[stab] = lnrhoref + mpoly0*alog(1.+beta*(z[stab]-z2)/Tref)
  ssinit[stab] = ssref $
                 + (1-mpoly0*(gamma-1))/gamma $
                   * alog(1.+beta*(z[stab]-z2)/Tref)
endif
;
unstab = where(z le z1)
if (unstab[0] ge 0) then begin
  lnrhoref = lnrhoref + mpoly0*alog(1.+beta*(z1-z2)/Tref)
  ssref = ssref $
          + (1-mpoly0*(gamma-1))/gamma $
            * alog(1.+beta*(z1-z2)/Tref)
  Tref = Tref + beta*(z1-z2)
  beta = gamma/gamma1*gravz/(mpoly1+1)
  Tinit[unstab] = Tref + beta*(z[unstab]-z1)
  lnrhoinit[unstab] = lnrhoref + mpoly1*alog(1.+beta*(z[unstab]-z1)/Tref)
  ssinit[unstab] = ssref $
                   + (1-mpoly1*(gamma-1))/gamma $
                     * alog(1.+beta*(z[unstab]-z1)/Tref)
endif

; anything else?


end
; End of file thermo.pro
