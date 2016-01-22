#!/usr/bin/env clisp 
;;;; Copyright (C) 2013-  Qiming Sun <osirpt.sun@gmail.com>

(load "gen-code.cl")

(gen-cint "auto_intor1.c"
  '("cint1e_ovlp_sph"       spheric  ( \| ))
  '("cint1e_nuc_sph"        spheric  ( \| nuc \| ))
  '("cint1e_kin_sph"        spheric  (.5 \| p dot p))
  '("cint1e_ia01p_sph"      spheric  (#C(0 1) \| nabla-rinv \| cross p))
  '("cint1e_giao_irjxp_sph" spheric  (#C(0 1) \| r cross p))
  '("cint1e_cg_irxp_sph"    spheric  (#C(0 1) \| rc cross p))
  '("cint1e_giao_a11part_sph" spheric (-.5 \| nabla-rinv \| r))
  '("cint1e_cg_a11part_sph" spheric  (-.5 \| nabla-rinv \| rc))
  '("cint1e_a01gp_sph"      spheric  (g \| nabla-rinv cross p \|))
  '("cint1e_igkin_sph"      spheric  (#C(0 .5) g \| p dot p))
  '("cint1e_igovlp_sph"     spheric  (#C(0 1) g \|))
  '("cint1e_ignuc_sph"      spheric  (#C(0 1) g \| nuc \|))
  '("cint1e_pnucp_sph"      spheric  (p* \| nuc dot p \| ))
  '("cint1e_z_sph"          spheric  ( \| zc \| ))
  '("cint1e_zz_sph"         spheric  ( \| zc zc \| ))
  '("cint1e_r_sph"          spheric  ( \| rc \| ))
  '("cint1e_r2_sph"         spheric  ( \| rc dot rc \| ))
  '("cint1e_rr_sph"         spheric  ( \| rc rc \| ))
  '("cint1e_z_origj_sph"    spheric  ( \| z \| ))
  '("cint1e_zz_origj_sph"   spheric  ( \| z z \| ))
  '("cint1e_r_origj_sph"    spheric  ( \| r \| ))
  '("cint1e_r2_origj_sph"   spheric  ( \| r dot r \| ))
  '("cint1e_rr_origj_sph"   spheric  ( \| r r \| ))
  '("cint1e_p4_sph"         spheric  ( p dot p \| p dot p ))
  ; use p* instead of p, to ignore the operator after it, then it can
  ; cross to the next p
  '("cint1e_prinvxp_sph"    spheric  (p* \| rinv cross p \| ))
  '("cint2e_p1vxp1_sph"     spheric  ( p* \, cross p \| \, )) ; SSO
  ;'("cint2e_sph"            spheric  ( \, \| \, ))
  '("cint2e_ig1_sph"        spheric  (#C(0 1) g \, \| \, ))
  '("cint2e_ig1ig2_sph"     spheric  (-1 g \, \| g \, ))
)

(gen-cint "auto_intor2.c"
  '("cint1e_ovlp"           spinor  ( \| ))
  '("cint1e_nuc"            spinor  ( \| nuc \|))
  '("cint1e_srsr"           spinor  (sigma dot r \| sigma dot r))
  '("cint1e_sr"             spinor  (sigma dot r \|))
  '("cint1e_srsp"           spinor  (sigma dot r \| sigma dot p))
  '("cint1e_spsp"           spinor  (sigma dot p \| sigma dot p))
  '("cint1e_sp"             spinor  (sigma dot p \|))
  '("cint1e_spnucsp"        spinor  (sigma dot p \| nuc \| sigma dot p))
  '("cint1e_srnucsr"        spinor  (sigma dot r \| nuc \| sigma dot r))
  '("cint1e_govlp"          spinor  (g \|))
  '("cint1e_gnuc"           spinor  (g \| nuc \|))
  '("cint1e_cg_sa10sa01"    spinor  (.5 sigma cross rc \| sigma cross nabla-rinv \|))
  '("cint1e_cg_sa10sp"      spinor  (.5 rc cross sigma \| sigma dot p))
  '("cint1e_cg_sa10nucsp"   spinor  (.5 rc cross sigma \| nuc \| sigma dot p))
  '("cint1e_giao_sa10sa01"  spinor  (.5 sigma cross r \| sigma cross nabla-rinv \|))
  '("cint1e_giao_sa10sp"    spinor  (.5 r cross sigma \| sigma dot p))
  '("cint1e_giao_sa10nucsp" spinor  (.5 r cross sigma \| nuc \| sigma dot p))
  '("cint1e_sa01sp"         spinor  (\| nabla-rinv cross sigma \| sigma dot p))
  '("cint1e_spgsp"          spinor  (g sigma dot p \| sigma dot p))
  '("cint1e_spgnucsp"       spinor  (g sigma dot p \| nuc \| sigma dot p))
  '("cint1e_spgsa01"        spinor  (g sigma dot p \| nabla-rinv cross sigma \|))
  ;'("cint2e"                spinor  (, \| \, ))
  '("cint2e_spsp1"          spinor  (sigma dot p \, sigma dot p \| \, ))
  '("cint2e_spsp1spsp2"     spinor  (sigma dot p \, sigma dot p \| sigma dot p \, sigma dot p ))
  '("cint2e_srsr1"          spinor  (sigma dot r \, sigma dot r \| \,))
  '("cint2e_srsr1srsr2"     spinor  (sigma dot r \, sigma dot r \| sigma dot r \, sigma dot r))
  '("cint2e_cg_sa10sp1"     spinor  (.5 rc cross sigma \, sigma dot p \| \,))
  '("cint2e_cg_sa10sp1spsp2" spinor (.5 rc cross sigma \, sigma dot p \| sigma dot p \, sigma dot p ))
  '("cint2e_giao_sa10sp1"   spinor  (.5 r cross sigma \, sigma dot p \| \,))
  '("cint2e_giao_sa10sp1spsp2" spinor (.5 r cross sigma \, sigma dot p \| sigma dot p \, sigma dot p ))
  '("cint2e_g1"             spinor  (g \, \| \,))
  '("cint2e_spgsp1"         spinor  (g sigma dot p \, sigma dot p \| \,))
  '("cint2e_g1spsp2"        spinor  (g \, \| sigma dot p \, sigma dot p))
  '("cint2e_spgsp1spsp2"    spinor  (g sigma dot p \, sigma dot p \| sigma dot p \, sigma dot p))
  ; for DKB
  '("cint1e_spspsp"         spinor  (sigma dot p \| sigma dot p sigma dot p))
  '("cint1e_spnuc"          spinor  (sigma dot p \| nuc \|))
  '("cint2e_spv1"           spinor  (sigma dot p \, \| \,))
  '("cint2e_vsp1"           spinor  (\, sigma dot p \| \,))
  '("cint2e_spsp2"          spinor  (\, \| sigma dot p \, sigma dot p))
  '("cint2e_spv1spv2"       spinor  (sigma dot p \, \| sigma dot p \,))
  '("cint2e_vsp1spv2"       spinor  (\, sigma dot p \| sigma dot p \,))
  '("cint2e_spv1vsp2"       spinor  (sigma dot p \, \| \, sigma dot p))
  '("cint2e_vsp1vsp2"       spinor  (\, sigma dot p \| \, sigma dot p))
  '("cint2e_spv1spsp2"      spinor  (sigma dot p \, \| sigma dot p \, sigma dot p))
  '("cint2e_vsp1spsp2"      spinor  (\, sigma dot p \| sigma dot p \, sigma dot p))
)

(gen-cint "auto_intor3.c"
  '("cint1e_ovlp_cart"        cart  ( \| ))
  '("cint1e_nuc_cart"         cart  ( \| nuc \| ))
  '("cint1e_kin_cart"         cart  (.5 \| p dot p))
  '("cint1e_ia01p_cart"       cart  (#C(0 1) \| nabla-rinv \| cross p))
  '("cint1e_giao_irjxp_cart"  cart  (#C(0 1) \| r cross p))
  '("cint1e_cg_irxp_cart"     cart  (#C(0 1) \| rc cross p))
  '("cint1e_giao_a11part_cart" cart (-.5 \| nabla-rinv \| r))
  '("cint1e_cg_a11part_cart"  cart  (-.5 \| nabla-rinv \| rc))
  '("cint1e_a01gp_cart"       cart  (g \| nabla-rinv cross p \|))
  '("cint1e_igkin_cart"       cart  (#C(0 .5) g \| p dot p))
  '("cint1e_igovlp_cart"      cart  (#C(0 1) g \|))
  '("cint1e_ignuc_cart"       cart  (#C(0 1) g \| nuc \|))
  '("cint2e_ig1_cart"         cart  (#C(0 1) g \, \| \, ))
)

(gen-cint "grad1.c"
  '("cint1e_ipovlp_sph"       spheric  (nabla \|))
  '("cint1e_ipkin_sph"        spheric  (.5 nabla \| p dot p))
  '("cint1e_ipnuc_sph"        spheric  (nabla \| nuc \|))
  '("cint1e_iprinv_sph"       spheric  (nabla \| rinv \|))
  '("cint1e_rinv_sph"         spheric  (\| rinv \|))
  '("cint2e_ip1_sph"          spheric  (nabla \, \| \,))
)

(gen-cint "grad2.c"
  '("cint1e_ipovlp"           spinor  (nabla \|))
  '("cint1e_ipkin"            spinor  (.5 nabla \| p dot p))
  '("cint1e_ipnuc"            spinor  (nabla \| nuc \|))
  '("cint1e_iprinv"           spinor  (nabla \| rinv \|))
  '("cint1e_ipspnucsp"        spinor  (nabla sigma dot p \| nuc \| sigma dot p))
  '("cint1e_ipsprinvsp"       spinor  (nabla sigma dot p \| rinv \| sigma dot p))
  '("cint2e_ip1"              spinor  (nabla \, \| \,))
  '("cint2e_ipspsp1"          spinor  (nabla sigma dot p \, sigma dot p \| \,))
  '("cint2e_ip1spsp2"         spinor  (nabla \, \| sigma dot p \, sigma dot p))
  '("cint2e_ipspsp1spsp2"     spinor  (nabla sigma dot p \, sigma dot p \| sigma dot p \, sigma dot p))
  '("cint2e_ipsrsr1"          spinor  (nabla sigma dot r \, sigma dot r \| \,))
  '("cint2e_ip1srsr2"         spinor  (nabla \, \| sigma dot r \, sigma dot r))
  '("cint2e_ipsrsr1srsr2"     spinor  (nabla sigma dot r \, sigma dot r \| sigma dot r \, sigma dot r))
)

(gen-cint "grad3.c"
  '("cint1e_ipovlp_cart"      cart  (nabla \|))
  '("cint1e_ipkin_cart"       cart  (.5 nabla \| p dot p))
  '("cint1e_ipnuc_cart"       cart  (nabla \| nuc \|))
  '("cint1e_iprinv_cart"      cart  (nabla \| rinv \|))
  '("cint1e_rinv_cart"        cart  (\| rinv \|))
  '("cint2e_ip1_cart"         cart  (nabla \, \| \,))
)

(gen-cint "gaunt1.c"
  '("cint2e_ssp1ssp2"         spinor  ( \, sigma dot p \| gaunt \| \, sigma dot p))
  '("cint2e_ssp1sps2"         spinor  ( \, sigma dot p \| gaunt \| sigma dot p \,))
  '("cint2e_sps1ssp2"         spinor  ( sigma dot p \, \| gaunt \| \, sigma dot p))
  '("cint2e_sps1sps2"         spinor  ( sigma dot p \, \| gaunt \| sigma dot p \,))
  '("cint2e_cg_ssa10ssp2"     spinor  (rc cross sigma \, \| gaunt \| \, sigma dot p))
  '("cint2e_giao_ssa10ssp2"   spinor  (r cross sigma  \, \| gaunt \| \, sigma dot p))
  '("cint2e_gssp1ssp2"        spinor  (g \, sigma dot p  \| gaunt \| \, sigma dot p))
)

(gen-cint "breit1.c"
  '("cint2e_gauge_r1_ssp1ssp2"  spinor  ( \, sigma dot p \| breit-r1 \| \, sigma dot p))
  '("cint2e_gauge_r1_ssp1sps2"  spinor  ( \, sigma dot p \| breit-r1 \| sigma dot p \,))
  '("cint2e_gauge_r1_sps1ssp2"  spinor  ( sigma dot p \, \| breit-r1 \| \, sigma dot p))
  '("cint2e_gauge_r1_sps1sps2"  spinor  ( sigma dot p \, \| breit-r1 \| sigma dot p \,))
  '("cint2e_gauge_r2_ssp1ssp2"  spinor  ( \, sigma dot p \| breit-r2 \| \, sigma dot p))
  '("cint2e_gauge_r2_ssp1sps2"  spinor  ( \, sigma dot p \| breit-r2 \| sigma dot p \,))
  '("cint2e_gauge_r2_sps1ssp2"  spinor  ( sigma dot p \, \| breit-r2 \| \, sigma dot p))
  '("cint2e_gauge_r2_sps1sps2"  spinor  ( sigma dot p \, \| breit-r2 \| sigma dot p \,))
)

(gen-cint "auto_3c2e.c"
  '("cint3c2e_ip1_sph"  spheric  (nabla \, \| ))
  '("cint3c2e_ip2_sph"  spheric  ( \, \| nabla))
  '("cint2c2e_ip1_sph"  spheric  (nabla \| r12 \| ))
  '("cint2c2e_ip2_sph"  spheric  ( \| r12 \| nabla))
  '("cint2e_ip2_sph"    spheric  ( \, \| r12 \| nabla \,))
  '("cint3c2e_ig1_sph"  spheric  (#C(0 1) g \, \| ))
  '("cint3c2e_ip1_spinor"     spinor   (nabla \, \| ))
  '("cint3c2e_ip2_spinor"     spinor   ( \, \| nabla))
  '("cint3c2e_spsp1_spinor"   spinor   (sigma dot p \, sigma dot p \| ))
  '("cint3c2e_ipspsp1_spinor" spinor   (nabla sigma dot p \, sigma dot p \| ))
  '("cint3c2e_spsp1ip2_spinor" spinor  (sigma dot p \, sigma dot p \| nabla ))
)
 
(gen-cint "auto_hess.c"
  '("cint2e_ipip1_sph"        spheric  ( nabla nabla \, \| \, ))
  '("cint2e_ipvip1_sph"       spheric  ( nabla \, nabla \| \, ))
  '("cint2e_ip1ip2_sph"       spheric  ( nabla \, \| nabla \, ))
)

(gen-cint "auto_3c1e.c"
  '("cint3c1e_r2_origk_sph"  spheric  ( \, \, r dot r))
  '("cint3c1e_r4_origk_sph"  spheric  ( \, \, r dot r r dot r))
  '("cint3c1e_r6_origk_sph"  spheric  ( \, \, r dot r r dot r r dot r))
  '("cint1e_r4_origj_sph"  spheric  ( \| r dot r r dot r))
)

