! Copyright (c) 2013,  Los Alamos National Security, LLC (LANS)
! and the University Corporation for Atmospheric Research (UCAR).
!
! Unless noted otherwise source code is licensed under the BSD license.
! Additional copyright and license information can be found in the LICENSE file
! distributed with this code, or at http://mpas-dev.github.com/license.html
!
!|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
!
!  ocn_vel_hmix
!
!> \brief MPAS ocean horizontal momentum mixing driver
!> \author Mark Petersen, Doug Jacobsen, Todd Ringler
!> \date   September 2011
!> \details
!>  This module contains the main driver routine for computing
!>  horizontal mixing tendencies.
!>
!>  It provides an init and a tend function. Each are described below.
!
!-----------------------------------------------------------------------

module ocn_vel_hmix

   use mpas_timer
   use mpas_derived_types
   use mpas_pool_routines
   use mpas_threading
   use ocn_vel_hmix_del2
   use ocn_vel_hmix_leith
   use ocn_vel_hmix_del4
   use ocn_constants
   use ocn_config

   implicit none
   private
   save

   !--------------------------------------------------------------------
   !
   ! Public parameters
   !
   !--------------------------------------------------------------------

   !--------------------------------------------------------------------
   !
   ! Public member functions
   !
   !--------------------------------------------------------------------

   public :: ocn_vel_hmix_tend, &
             ocn_vel_hmix_init

   !--------------------------------------------------------------------
   !
   ! Private module variables
   !
   !--------------------------------------------------------------------

   logical :: hmixOn

!***********************************************************************

contains

!***********************************************************************
!
!  routine ocn_vel_hmix_tend
!
!> \brief   Computes tendency term for horizontal momentum mixing
!> \author  Mark Petersen, Doug Jacobsen, Todd Ringler
!> \date    September 2011
!> \details
!>  This routine computes the horizontal mixing tendency for momentum
!>  based on current state and user choices of mixing parameterization.
!>  Multiple parameterizations may be chosen and added together.  These
!>  tendencies are generally computed by calling the specific routine
!>  for the chosen parameterization, so this routine is primarily a
!>  driver for managing these choices.
!
!-----------------------------------------------------------------------

   subroutine ocn_vel_hmix_tend(meshPool, scratchPool, divergence, relativeVorticity, normalVelocity, tangentialVelocity, &
                                viscosity, tend, err)!{{{

      !-----------------------------------------------------------------
      !
      ! input variables
      !
      !-----------------------------------------------------------------

      type (mpas_pool_type), intent(in) :: &
         meshPool          !< Input: mesh information

      type (mpas_pool_type), intent(inout) :: scratchPool !< Input: scratch variables

      real (kind=RKIND), dimension(:,:), intent(in) :: &
         divergence    !< Input: velocity divergence

      real (kind=RKIND), dimension(:,:), intent(in) :: &
         relativeVorticity     !< Input: relative vorticity

      real (kind=RKIND), dimension(:,:), intent(in) :: &
         normalVelocity     !< Input: velocity normal to an edge

      real (kind=RKIND), dimension(:,:), intent(in) :: &
         tangentialVelocity     !< Input: velocity, tangent to an edge

      !-----------------------------------------------------------------
      !
      ! input/output variables
      !
      !-----------------------------------------------------------------

      real (kind=RKIND), dimension(:,:), intent(inout) :: &
         viscosity     !< Input: viscosity

      real (kind=RKIND), dimension(:,:), intent(inout) :: &
         tend          !< Input/Output: velocity tendency

      !-----------------------------------------------------------------
      !
      ! output variables
      !
      !-----------------------------------------------------------------

      integer, intent(out) :: err !< Output: error flag

      !-----------------------------------------------------------------
      !
      ! local variables
      !
      !-----------------------------------------------------------------

      integer :: err1

      !-----------------------------------------------------------------
      !
      ! call relevant routines for computing tendencies
      ! note that the user can choose multiple options and the
      !   tendencies will be added together
      !
      !-----------------------------------------------------------------

      if(.not.hmixOn) return

      call mpas_timer_start("vel hmix")

      viscosity = 0.0_RKIND
      err = 0

      call ocn_vel_hmix_del2_tend(meshPool, divergence, relativeVorticity, viscosity, tend, err1)
      err = ior(err1, err)

      call ocn_vel_hmix_leith_tend(meshPool, divergence, relativeVorticity, viscosity, tend, err1)
      err = ior(err1, err)

      call ocn_vel_hmix_del4_tend(meshPool, divergence, relativeVorticity, tend, err1)
      err = ior(err1, err)

      call mpas_timer_stop("vel hmix")

   !--------------------------------------------------------------------

   end subroutine ocn_vel_hmix_tend!}}}

!***********************************************************************
!
!  routine ocn_vel_hmix_init
!
!> \brief   Initializes ocean momentum horizontal mixing quantities
!> \author  Mark Petersen, Doug Jacobsen, Todd Ringler
!> \date    September 2011
!> \details
!>  This routine initializes a variety of quantities related to
!>  horizontal velocity mixing in the ocean. Since a variety of
!>  parameterizations are available, this routine primarily calls the
!>  individual init routines for each parameterization.
!
!-----------------------------------------------------------------------

   subroutine ocn_vel_hmix_init(err)!{{{

   !--------------------------------------------------------------------

      !-----------------------------------------------------------------
      !
      ! call individual init routines for each parameterization
      !
      !-----------------------------------------------------------------

      integer, intent(out) :: err !< Output: error flag

      integer :: err1, err2, err3

      hmixOn = .true.

      call ocn_vel_hmix_del2_init(err1)
      call ocn_vel_hmix_leith_init(err2)
      call ocn_vel_hmix_del4_init(err3)

      err = ior(ior(err1, err2),err3)

      if(config_disable_vel_hmix) hmixOn = .false.

   !--------------------------------------------------------------------

   end subroutine ocn_vel_hmix_init!}}}

!***********************************************************************

end module ocn_vel_hmix

!|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
! vim: foldmethod=marker
