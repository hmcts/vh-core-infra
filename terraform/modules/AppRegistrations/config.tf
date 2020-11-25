locals {
  app_permissions = {
    "booking-queue-subscriber" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
          DirectoryReadWriteAll = {
            id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175"
            type = "Role"
          }
        }
      }
    }
    "scheduler-jobs" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
          DirectoryReadWriteAll = {
            id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175"
            type = "Role"
          }
        }
      }
    }
    "video-queue-subscriber" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
          DirectoryReadWriteAll = {
            id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175"
            type = "Role"
          }
        }
      }
    }
    "admin-web" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
          DirectoryReadWriteAll = {
            id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175"
            type = "Role"
          }
        }
      }
      "Microsoft Graph" = {
        id = "00000003-0000-0000-c000-000000000000"
        access = {
          GroupReadWriteAll = {
            id   = "62a82d76-70ea-41e2-9197-370581804d09"
            type = "Role"
          }
        }
      }
    }
    "service-web" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
          DirectoryReadWriteAll = {
            id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175"
            type = "Role"
          }
        }
      }
      "Microsoft Graph" = {
        id = "00000003-0000-0000-c000-000000000000"
        access = {
          UserReadAll = {
            id   = "df021288-bdef-4463-88db-98f22de89214"
            type = "Role"
          }
          GroupReadWriteAll = {
            id   = "62a82d76-70ea-41e2-9197-370581804d09"
            type = "Role"
          }
        }
      }
    }
    "video-web" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
        }
      }
    }
    "bookings-api" = {
    }
    "user-api" = {
      "Azure AD Graph" = {
        id = "00000002-0000-0000-c000-000000000000"
        access = {
          UserRead = {
            id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
            type = "Scope"
          }
          DirectoryReadWriteAll = {
            id   = "78c8a3c8-a07e-4b9e-af1b-b5ccab50a175"
            type = "Role"
          }
        }
      }
      "Microsoft Graph" = {
        id = "00000003-0000-0000-c000-000000000000"
        access = {
          UserReadWriteAll = {
            id   = "741f803b-c850-494e-b5df-cde7c675a1ca"
            type = "Role"
          }
          GroupReadWriteAll = {
            id   = "62a82d76-70ea-41e2-9197-370581804d09"
            type = "Role"
          }
        }
      }
    }
    "video-api" = {
    }
    "notification-api-shaed" = {
    }
  }

  app_roles = {
    bookings-api = []
    video-api = []
    user-api = []
    notification-api-shaed = []
    admin-web = [
      {
        allowed_member_types = ["User"]
        description          = "This user can book hearings and support live hearings via the admin portal" 
        display_name         = "Video Hearings Officer"
        is_enabled           = true
        value                = "VHO"
      },
      {
        allowed_member_types = ["User"]
        description          = "This user is able to attend a hearing and perform self tests" 
        display_name         = "Citizen"
        is_enabled           = true
        value                = "Citizen"
      },
      {
        allowed_member_types = ["User"]
        description          = "This user is able to attend a hearing and perform self tests" 
        display_name         = "Legal Representative"
        is_enabled           = true
        value                = "ProfessionalUser"
      },
      {
        allowed_member_types = ["User"]
        description          = "This user is able to conduct hearings as a judge." 
        display_name         = "Judge"
        is_enabled           = true
        value                = "Judge"
      }
    ]    
    video-web = [
      {
        allowed_member_types = ["User"]
        description          = "This user can book hearings and support live hearings via the admin portal" 
        display_name         = "Video Hearings Officer"
        is_enabled           = true
        value                = "VHO"
      },
      {
        allowed_member_types = ["User"]
        description          = "This user is able to attend a hearing and perform self tests" 
        display_name         = "Citizen"
        is_enabled           = true
        value                = "Citizen"
      },
      {
        allowed_member_types = ["User"]
        description          = "This user is able to attend a hearing and perform self tests" 
        display_name         = "Legal Representative"
        is_enabled           = true
        value                = "ProfessionalUser"
      },
      {
        allowed_member_types = ["User"]
        description          = "This user is able to conduct hearings as a judge." 
        display_name         = "Judge"
        is_enabled           = true
        value                = "Judge"
      }
    ]
    service-web = []
    notification-api-shaed = []
    scheduler-jobs = []
    booking-queue-subscriber = []
  }

  oauth2_allow_implicit_flow = {
    "booking-queue-subscriber" = false
    "video-queue-subscriber"   = false
    "admin-web"                = true
    "service-web"              = true
    "video-web"                = true
    "bookings-api"             = false
    "user-api"                 = false
    "video-api"                = false
    "notification-api-shaed"   = false
  }
}
