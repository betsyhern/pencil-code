;
; $Id: pc_magic_var.pro,v 1.31 2008-01-18 12:30:37 ajohan Exp $
;
;  Author: Tony Mee (A.J.Mee@ncl.ac.uk)
;  $Date: 2008-01-18 12:30:37 $
;  $Revision: 1.31 $
;
;  25-may-04/tony: coded 
;
; Utility routine to automatically construct expressions for commonly
; requested variable from variables stored in a var file. 
;
; The routine is not really desigend to be called directly
; but rather it is intended as a utility function for other
; routines such as pc_read_var.
;
; Having these shortcuts makes using transformation routines
; like pc_eoscalc that have been written in a very high-level
; general purpose way somewhat less t
;
; See idl/magic/pc_magic_var.pro to view/add useful variables.
; NB the behaviour of pc_read_magic can be dependent upon other parameters etc.
; eg. calculation of pressure is achieved using ss for noionization and lnTT for ionization.
;
;  Examples:
;  A)
;    pc_init
;    pc_read_var,obj=data,variables=['uu','lnrho','bb','tt'],/MAGIC
;
;  Will return (if available) a structure with elements uu, lnrho, bb and
;  tt respectively containing Velocity, Log Density, Magnetic Field and 
;  Temperature fields.
;
;  B)
;    pc_init
;    pc_read_var,obj=mydata,variables=['uu','lnrho','bb','divu','pp'],/MAGIC
;  Is equivalent to:
;    pc_read_var,obj=mydata,variables=['uu','lnrho','curl(aa)','div(uu)', $
;                                       'pc_eoscalc(lnrho,ss,/pp,/lnrho_ss)'], $
;                                 tags=['uu','lnrho','bb','divu','pp']
;
;  NB. pc_init must be called prior to any possible derivative usage 
;      (e.g. here bb = curl(aa) )
;      
;  Current mappings: 
;
;    xx      -> X-Coordinate at every point 
;    yy      -> Y-Coordinate at every point 
;    zz      -> Z-Coordinate at every point 
;    rr      -> R-Coordinate at every point 
;    rho     -> Gas density 
;    bb      -> Magnetic field vector
;    divu    -> Divergence of velocity
;    u2      -> Modulus of velocity
;    cs2     -> Sound speed squared
;    ee      -> Specific energy
;    tt      -> Temperature
;    lntt    -> ln Temperature
;    pp      -> Thermal Pressure
; Dust
;    rhod    -> Dust density
;    fd      -> Dust distribution function dn = f dm
;    ad      -> Dust grain radius
;    epsd    -> Dust-to-gas ratio (sum over all bins)
;    smon    -> Supersaturation level Pmon/Psat
;    unit_md -> Dust mass unit
;    mdave   -> Average grain mass (mean over all bins)
; Interstellar
;    ismcool -> Interstellar cooling (Switched by params cooling_select)
; Gross-Pitaevskii Equation (Bose-Einstein Condensate)
;    psi2    -> mod psi squared (density squared)
;    argpsi  -> atan(imag(psi),real(psi))
;
;
pro pc_magic_var,variables,tags,param=param,datadir=datadir
;
  if (not keyword_set(datadir)) then datadir='data'
  if (n_elements(param) eq 0) then $
      pc_read_param,object=param,datadir=datadir,/quiet
;
;  Dependencies.
;
  pc_magic_var_dep, variables, tags, 'mten', 'bb'
  pc_magic_var_dep, variables, tags, 'mten', 'bij'
  pc_magic_var_dep, variables, tags, 'mpres', 'bb'
  pc_magic_var_dep, variables, tags, 'mpres', 'bij'
;
;  Modules.
;
  lionization = safe_get_tag(param,'lionization',default=safe_get_tag(param,'leos_ionization',default=0)) 
  lionization_fixed = safe_get_tag(param,'lionization_fixed',default=safe_get_tag(param,'leos_ionizationi_fixed',default=0)) 
  lentropy = safe_get_tag(param,'lentropy',default=safe_get_tag(param,'lentropy',default=0)) 
;
  for iv=0,n_elements(variables)-1 do begin
; x Coordinate
    if (variables[iv] eq 'xx') then begin
      tags[iv]=variables[iv]
      variables[iv]='spread(spread(x,1,n_elements(y)),2,n_elements(z))'
; y Coordinate
    endif else if (variables[iv] eq 'yy') then begin
      tags[iv]=variables[iv]
      variables[iv]='spread(spread(y,0,n_elements(x)),2,n_elements(z))'
; z Coordinate
    endif else if (variables[iv] eq 'zz') then begin
      tags[iv]=variables[iv]
      variables[iv]='spread(spread(z,0,n_elements(x)),1,n_elements(y))'
; r Coordinate
    endif else if (variables[iv] eq 'rr') then begin
      tags[iv]=variables[iv]
      variables[iv]='sqrt(spread(spread(x^2,1,n_elements(y)),2,n_elements(z))+spread(spread(y^2,0,n_elements(x)),2,n_elements(z))+spread(spread(z^2,0,n_elements(x)),1,n_elements(y)))'
; Magnetic field vector
    endif else if (variables[iv] eq 'bb') then begin
      tags[iv]=variables[iv]
      variables[iv]='curl(aa)'
; Current density [jj=curl(bb)=curl(curl(aa))=grad(div(a))-del2(aa)]
    endif else if (variables[iv] eq 'jj') then begin
      tags[iv]=variables[iv]
      variables[iv]='graddiv(aa)-del2(aa)'
; Derivative vector
    endif else if (variables[iv] eq 'd2A') then begin
      tags[iv]=variables[iv]
      variables[iv]='derij(aa)'
; Derivative vector
    endif else if (variables[iv] eq 'bij') then begin
      tags[iv]=variables[iv]
      variables[iv]='derijcurl(aa)'
; Lorentz force
    endif else if (variables[iv] eq 'flor') then begin
      tags[iv]=variables[iv]
      if (param.ldensity_nolog) then begin
        variables[iv]='spread(1/lnrho,3,3)*cross(curlcurl(aa),curl(aa))'
      endif else begin
        variables[iv]='spread(1/exp(lnrho),3,3)*cross(curlcurl(aa),curl(aa))'
      endelse
; Magnetic tension
    endif else if (variables[iv] eq 'mten') then begin
      tags[iv]=variables[iv]
      if (param.ldensity_nolog) then begin
        variables[iv]='spread(1/lnrho,3,3)*[total(bb*reform(bij[*,*,*,0,*]),4),total(bb*reform(bij[*,*,*,1,*]),4),total(bb*reform(bij[*,*,*,2,*]),4)]'
      endif else begin
        variables[iv]='spread(1/exp(lnrho),3,3)*[total(bb*reform(bij[*,*,*,0,*]),4),total(bb*reform(bij[*,*,*,1,*]),4),total(bb*reform(bij[*,*,*,2,*]),4)]'
      endelse
; Magnetic pressure
    endif else if (variables[iv] eq 'mpres') then begin
      tags[iv]=variables[iv]
      if (param.ldensity_nolog) then begin
        variables[iv]='spread(1/lnrho,3,3)*[total(bb*reform(bij[*,*,*,*,0]),4),total(bb*reform(bij[*,*,*,*,1]),4),total(bb*reform(bij[*,*,*,*,2]),4)]'
      endif else begin
        variables[iv]='spread(1/exp(lnrho),3,3)*[total(bb*reform(bij[*,*,*,*,0]),4),total(bb*reform(bij[*,*,*,*,1]),4),total(bb*reform(bij[*,*,*,*,2]),4)]'
      endelse
; Vorticity
    endif else if (variables[iv] eq 'oo') then begin
      tags[iv]=variables[iv]
      variables[iv]='curl(uu)'
; Divergence of velocity
    endif else if (variables[iv] eq 'divu') then begin
      tags[iv]=variables[iv]
      variables[iv]='div(uu)'
; Gas Density 
    endif else if (variables[iv] eq 'rho') then begin
      tags[iv]=variables[iv]
      variables[iv]='exp(lnrho)'
; Velocity advection
    endif else if (variables[iv] eq 'advu') then begin
      tags[iv]=variables[iv]
      variables[iv]='-0.5*grad(dot2(uu))+cross(uu,curl(uu))'
; Density advection
    endif else if (variables[iv] eq 'advlnrho') then begin
      tags[iv]=variables[iv]
      variables[iv]='-dot(uu,grad(lnrho))'
; Density advection (non-logarithmic density)
    endif else if (variables[iv] eq 'advrho') then begin
      tags[iv]=variables[iv]
      variables[iv]='-dot(uu,grad(lnrho))'
; Modulus of velocity
    endif else if (variables[iv] eq 'u2') then begin
      tags[iv]=variables[iv]
      variables[iv]='dot2(uu)'
; Sound speed squared
    endif else if (variables[iv] eq 'cs2') then begin
      tags[iv]=variables[iv]
      if (lionization and not lionization_fixed) then begin
        variables[iv]='pc_eoscalc(lnrho,lnTT,/cs2,/lnrho_lnTT,dim=dim,param=param,datadir=datadir)'
      endif else begin
        variables[iv]='pc_eoscalc(lnrho,ss,/cs2,/lnrho_ss,dim=dim,param=param,datadir=datadir)'
      endelse
; Pressure gradient
    endif else if (variables[iv] eq 'fpres') then begin
      tags[iv]=variables[iv]
      if (param.ldensity_nolog) then begin
        variables[iv]='-grad(lnrho)'
      endif else begin
        variables[iv]='spread(-1/lnrho,3,3)*grad(lnrho)'
      endelse
; Specific energy
    endif else if (variables[iv] eq 'ee') then begin
      tags[iv]=variables[iv]
      if (lionization and not lionization_fixed) then begin
        variables[iv]='pc_eoscalc(lnrho,lnTT,/ee,/lnrho_lnTT,dim=dim,param=param,datadir=datadir)'
      endif else begin
        variables[iv]='pc_eoscalc(lnrho,ss,/ee,/lnrho_ss,dim=dim,param=param,datadir=datadir)'
      endelse
; Temperature
    endif else if (variables[iv] eq 'tt') then begin
      tags[iv]=variables[iv]
      if (lionization and not lionization_fixed) then begin
        variables[iv]='exp(lnTT)'
      endif else begin
        variables[iv]='pc_eoscalc(lnrho,ss,/tt,/lnrho_ss,dim=dim,param=param,datadir=datadir)'
      endelse
; Logarithm of temperature
    endif else if (variables[iv] eq 'lntt') then begin
      tags[iv]=variables[iv]
      if (lionization and not lionization_fixed) then begin
        variables[iv]='lnTT'
      endif else begin
        variables[iv]='pc_eoscalc(lnrho,ss,/lntt,/lnrho_ss,dim=dim,param=param,datadir=datadir)'
      endelse
; Entropy ss
    endif else if (variables[iv] eq 'ss') then begin
      tags[iv]=variables[iv]
      if (lionization and not lionization_fixed) then begin
        message,"Thermodynamic combination not implemented yet: /ss from lnrho and lnTT with lionization"
      endif else begin
        if (lentropy ne -1) then variables[iv]='pc_eoscalc(lnrho,lnTT,/ss,/lnrho_lnTT,dim=dim,param=param,datadir=datadir)' else variables[iv]='ss'
      endelse
; Pressure
    endif else if (variables[iv] eq 'pp') then begin
      tags[iv]=variables[iv]
      if (lionization and not lionization_fixed) then begin
        variables[iv]='pc_eoscalc(lnrho,lnTT,/pp,/lnrho_lnTT,dim=dim,param=param,datadir=datadir)'
      endif else begin
        variables[iv]='pc_eoscalc(lnrho,ss,/pp,/lnrho_ss,dim=dim,param=param,datadir=datadir)'
      endelse
; Divergence of dust velocity
    endif else if (variables[iv] eq 'divud') then begin
      tags[iv]=variables[iv]
      variables[iv]='div(uud)'
; Dust density
    endif else if (variables[iv] eq 'rhod') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(nd=nd,md=md,param=param,var='rhod')"
; Dust distribution function dn = f dm
    endif else if (variables[iv] eq 'fd') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(nd=nd,param=param,var='fd')"
; Dust grain radius
    endif else if (variables[iv] eq 'ad') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(md=md,param=param,var='ad')"
; Dust-to-gas ratio (sum over all bins)
    endif else if (variables[iv] eq 'epsd') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(lnrho=lnrho,nd=nd,md=md,par=param,var='epsd')"
; Supersaturation level Pmon/Psat
    endif else if (variables[iv] eq 'smon') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(lnrho=lnrho,ss=ss,nd=nd,md=md," + $
          "param=param,datadir=datadir,var='smon')"
; Dust mass unit
    endif else if (variables[iv] eq 'unit_md') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(param=param,var='unit_md')"
; Average grain mass (mean over all bins)
    endif else if (variables[iv] eq 'mdave') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_dust_aux(nd=nd,md=md,param=param,var='mdave')"
; Interstellar cooling term (as switched by the cooling_select param.)
    endif else if (variables[iv] eq 'ismcool') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_interstellar_cool(lnrho=lnrho,ss=ss,param=param)"
; Particle velocity
    endif else if (variables[iv] eq 'vvp') then begin
      tags[iv]=variables[iv]
      variables[iv]="pc_particles_aux(np=np,vvpsum=vvpsum,dim=dim,var='vvp')"
; Absolute value of the wavefunction squared
    endif else if (variables[iv] eq 'psi2') then begin
      tags[iv]=variables[iv]
      variables[iv]="psi_real^2+psi_imag^2"
; Argument of the complex wavefunction
    endif else if (variables[iv] eq 'argpsi') then begin
      tags[iv]=variables[iv]
      variables[iv]="atan(psi_imag,psi_real)"
    endif
  endfor
;
end
;
pro pc_magic_var_dep, variables, tags, var, dep
;
;  Resolve dependencies of magic variables.
;
;  Author: Anders Johansen
;
  iv=where(variables eq var) & iv=min(iv)
;
;  If variable is requested, put dependencies in the variables array.
;
  if (iv ge 0) then begin
    iv1=where(variables eq dep) & iv1=min(iv1)
    if (iv1 eq -1) then begin
      variables=[variables[0:iv-1],dep,variables[iv:n_elements(variables)-1]]
      tags     =[     tags[0:iv-1],dep,     tags[iv:n_elements(tags     )-1]]
    endif
;
;  Move dependencies so that they are calculated before the variables.
;
    var=variables[iv]
    iv =where(variables eq var) & iv =min(iv)
    iv1=where(variables eq dep) & iv1=min(iv1)
    if (iv1 gt iv) then begin
      index=indgen(n_elements(variables))
      index[iv]=iv1 & index[iv1]=iv
      variables=variables[index] & tags=tags[index]
    endif
  endif
;
end
