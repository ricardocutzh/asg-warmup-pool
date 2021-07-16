variable identifier {
  type        = string
  default     = "ricardo"
  description = "identifier"
}


variable min_size {
  type        = number
  default     = 0
}


variable max_size {
  type        = number
  default     = 0
}

variable warm_pool_min_size {
  type        = number
  default     = 0
}

variable warm_pool_max_size {
  type        = number
  default     = 0
}

variable warm_pool_state {
  type        = string
  default     = "Running"
}