# 0 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
# 61 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
        .syntax unified
# 73 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
.macro VECTOR Name=
        .section .vectors, "ax"
        .code 16
        .word \Name
.endm




.macro EXC_HANDLER Name=



        .section .vectors, "ax"
        .word \Name



        .section .init.\Name, "ax"
        .thumb_func
        .weak \Name
        .balign 2
\Name:
        1: b 1b
.endm




.macro ISR_HANDLER Name=



        .section .vectors, "ax"
        .word \Name
# 116 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
        .section .init.\Name, "ax"
        .thumb_func
        .weak \Name
        .balign 2
\Name:
        1: b 1b

.endm




.macro ISR_RESERVED
        .section .vectors, "ax"
        .word 0
.endm




.macro ISR_RESERVED_DUMMY
        .section .vectors, "ax"
        .word Dummy_Handler
.endm







        .extern __stack_end__
        .extern Reset_Handler
        .extern HardFault_Handler
# 163 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
        .section .vectors, "ax"
        .code 16
        .balign 512
        .global _vectors
_vectors:



        VECTOR __stack_end__
        VECTOR Reset_Handler
        EXC_HANDLER NMI_Handler
        VECTOR HardFault_Handler





        EXC_HANDLER MemManage_Handler
        EXC_HANDLER BusFault_Handler
        EXC_HANDLER UsageFault_Handler

        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        EXC_HANDLER SVC_Handler



        EXC_HANDLER DebugMon_Handler

        ISR_RESERVED
        EXC_HANDLER PendSV_Handler
        EXC_HANDLER SysTick_Handler




        ISR_HANDLER WWDG_IRQHandler
        ISR_HANDLER PVD_PVM_IRQHandler
        ISR_HANDLER TAMP_STAMP_IRQHandler
        ISR_HANDLER RTC_WKUP_IRQHandler
        ISR_HANDLER FLASH_IRQHandler
        ISR_HANDLER RCC_IRQHandler
        ISR_HANDLER EXTI0_IRQHandler
        ISR_HANDLER EXTI1_IRQHandler
        ISR_HANDLER EXTI2_IRQHandler
        ISR_HANDLER EXTI3_IRQHandler
        ISR_HANDLER EXTI4_IRQHandler
        ISR_HANDLER DMA1_Channel1_IRQHandler
        ISR_HANDLER DMA1_Channel2_IRQHandler
        ISR_HANDLER DMA1_Channel3_IRQHandler
        ISR_HANDLER DMA1_Channel4_IRQHandler
        ISR_HANDLER DMA1_Channel5_IRQHandler
        ISR_HANDLER DMA1_Channel6_IRQHandler
        ISR_HANDLER DMA1_Channel7_IRQHandler
        ISR_HANDLER ADC1_IRQHandler
        ISR_HANDLER CAN1_TX_IRQHandler
        ISR_HANDLER CAN1_RX0_IRQHandler
        ISR_HANDLER CAN1_RX1_IRQHandler
        ISR_HANDLER CAN1_SCE_IRQHandler
        ISR_HANDLER EXTI9_5_IRQHandler
        ISR_HANDLER TIM1_BRK_TIM15_IRQHandler
        ISR_HANDLER TIM1_UP_TIM16_IRQHandler
        ISR_HANDLER TIM1_TRG_COM_IRQHandler
        ISR_HANDLER TIM1_CC_IRQHandler
        ISR_HANDLER TIM2_IRQHandler
        ISR_RESERVED
        ISR_RESERVED
        ISR_HANDLER I2C1_EV_IRQHandler
        ISR_HANDLER I2C1_ER_IRQHandler
        ISR_RESERVED
        ISR_RESERVED
        ISR_HANDLER SPI1_IRQHandler
        ISR_RESERVED
        ISR_HANDLER USART1_IRQHandler
        ISR_HANDLER USART2_IRQHandler
        ISR_RESERVED
        ISR_HANDLER EXTI15_10_IRQHandler
        ISR_HANDLER RTC_Alarm_IRQHandler
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_HANDLER SPI3_IRQHandler
        ISR_RESERVED
        ISR_RESERVED
        ISR_HANDLER TIM6_DAC_IRQHandler
        ISR_HANDLER TIM7_IRQHandler
        ISR_HANDLER DMA2_Channel1_IRQHandler
        ISR_HANDLER DMA2_Channel2_IRQHandler
        ISR_HANDLER DMA2_Channel3_IRQHandler
        ISR_HANDLER DMA2_Channel4_IRQHandler
        ISR_HANDLER DMA2_Channel5_IRQHandler
        ISR_RESERVED
        ISR_RESERVED
        ISR_RESERVED
        ISR_HANDLER COMP_IRQHandler
        ISR_HANDLER LPTIM1_IRQHandler
        ISR_HANDLER LPTIM2_IRQHandler
        ISR_HANDLER USB_IRQHandler
        ISR_HANDLER DMA2_Channel6_IRQHandler
        ISR_HANDLER DMA2_Channel7_IRQHandler
        ISR_HANDLER LPUART1_IRQHandler
        ISR_HANDLER QUADSPI_IRQHandler
        ISR_HANDLER I2C3_EV_IRQHandler
        ISR_HANDLER I2C3_ER_IRQHandler
        ISR_HANDLER SAI1_IRQHandler
        ISR_RESERVED
        ISR_HANDLER SWPMI1_IRQHandler
        ISR_HANDLER TSC_IRQHandler
        ISR_RESERVED
        ISR_RESERVED
        ISR_HANDLER RNG_IRQHandler
        ISR_HANDLER FPU_IRQHandler
        ISR_HANDLER CRS_IRQHandler


        .section .vectors, "ax"
_vectors_end:
# 308 "C:\\Users\\ramms\\Documents\\SEGGER Embedded Studio Projects\\I2Stest\\STM32L4xx\\Source\\stm32l432xx_Vectors.s"
        .section .init.Dummy_Handler, "ax"
        .thumb_func
        .weak Dummy_Handler
        .balign 2
Dummy_Handler:
        1: b 1b
