/*******************************************************************************
Copyright(c) ArcSoft, All right reserved.

This file is ArcSoft's property. It contains ArcSoft's trade secret, proprietary 
and confidential information. 

The information and code contained in this file is only for authorized ArcSoft 
employees to design, create, modify, or review.

DO NOT DISTRIBUTE, DO NOT DUPLICATE OR TRANSMIT IN ANY FORM WITHOUT PROPER 
AUTHORIZATION.

If you are not an intended recipient of this file, you must not copy, 
distribute, modify, or take any action in reliance on it. 

If you have received this file in error, please immediately notify ArcSoft and 
permanently delete the original and any copy of any file and any printout 
thereof.
*******************************************************************************/
#ifndef __ASVL_OFFSCREEN_H__
#define __ASVL_OFFSCREEN_H__

#import <ArcSoftFaceEngine/amcomdef.h>

#ifdef __cplusplus
extern "C" {
#endif


/*31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 */


/* R  R  R  R  R  G  G  G  G  G  G  B  B  B  B  B */
#define		ASVL_PAF_RGB16_B5G6R5		0x101
/* X  R  R  R  R  R  G  G  G  G  G  B  B  B  B  B */
#define		ASVL_PAF_RGB16_B5G5R5		0x102
/* X  X  X  X  R  R  R  R  G  G  G  G  B  B  B  B */
#define		ASVL_PAF_RGB16_B4G4R4		0x103
/* T  R  R  R  R  R  G  G  G  G  G  B  B  B  B  B */ 
#define		ASVL_PAF_RGB16_B5G5R5T		0x104
/* B  B  B  B  B  G  G  G  G  G  G  R  R  R  R  R */ 
#define		ASVL_PAF_RGB16_R5G6B5		0x105
/* X  B  B  B  B  B  G  G  G  G  G  R  R  R  R  R */  
#define		ASVL_PAF_RGB16_R5G5B5		0x106
/* X  X  X  X  B  B  B  B  G  G  G  G  R  R  R  R */ 
#define		ASVL_PAF_RGB16_R4G4B4		0x107


/* R	R  R  R	 R	R  R  R  G  G  G  G  G  G  G  G  B  B  B  B  B  B  B  B */
#define		ASVL_PAF_RGB24_B8G8R8		0x201
/* X	X  X  X	 X	X  R  R  R  R  R  R  G  G  G  G  G  G  B  B  B  B  B  B */ 
#define		ASVL_PAF_RGB24_B6G6R6		0x202
/* X	X  X  X	 X	T  R  R  R  R  R  R  G  G  G  G  G  G  B  B  B  B  B  B */ 
#define		ASVL_PAF_RGB24_B6G6R6T		0x203
/* B  B  B  B  B  B  B  B  G  G  G  G  G  G  G  G  R	R  R  R	 R	R  R  R */
#define		ASVL_PAF_RGB24_R8G8B8		0x204
/* X	X  X  X	 X	X  B  B  B  B  B  B  G  G  G  G  G  G  R  R  R  R  R  R */
#define		ASVL_PAF_RGB24_R6G6B6		0x205

/* X	X  X  X	 X	X  X  X	 R	R  R  R	 R	R  R  R  G  G  G  G  G  G  G  G  B  B  B  B  B  B  B  B */ 
#define		ASVL_PAF_RGB32_B8G8R8		0x301
/* A	A  A  A	 A	A  A  A	 R	R  R  R	 R	R  R  R  G  G  G  G  G  G  G  G  B  B  B  B  B  B  B  B */ 
#define		ASVL_PAF_RGB32_B8G8R8A8		0x302
/* X	X  X  X	 X	X  X  X	 B  B  B  B  B  B  B  B  G  G  G  G  G  G  G  G  R	R  R  R	 R	R  R  R */ 
#define		ASVL_PAF_RGB32_R8G8B8		0x303
/* B    B  B  B  B  B  B  B  G  G  G  G  G  G  G  G  R  R  R  R  R  R  R  R  A	A  A  A  A	A  A  A */
#define		ASVL_PAF_RGB32_A8R8G8B8		0x304
/* A    A  A  A  A  A  A  A  B  B  B  B  B  B  B  B  G  G  G  G  G  G  G  G  R  R  R  R  R	R  R  R */
#define		ASVL_PAF_RGB32_R8G8B8A8		0x305

/*Y0, U0, V0*/																				
#define		ASVL_PAF_YUV				0x401
/*Y0, V0, U0*/																				
#define		ASVL_PAF_YVU				0x402
/*U0, V0, Y0*/																				
#define		ASVL_PAF_UVY				0x403
/*V0, U0, Y0*/																				
#define		ASVL_PAF_VUY				0x404

/*Y0, U0, Y1, V0*/																			
#define		ASVL_PAF_YUYV				0x501
/*Y0, V0, Y1, U0*/																			
#define		ASVL_PAF_YVYU				0x502
/*U0, Y0, V0, Y1*/																			
#define		ASVL_PAF_UYVY				0x503
/*V0, Y0, U0, Y1*/																			
#define		ASVL_PAF_VYUY				0x504
/*Y1, U0, Y0, V0*/																			
#define		ASVL_PAF_YUYV2				0x505
/*Y1, V0, Y0, U0*/																		
#define		ASVL_PAF_YVYU2				0x506
/*U0, Y1, V0, Y0*/																			
#define		ASVL_PAF_UYVY2				0x507
/*V0, Y1, U0, Y0*/																			
#define		ASVL_PAF_VYUY2				0x508
/*Y0, Y1, U0, V0*/																			
#define		ASVL_PAF_YYUV				  0x509

/*8 bit Y plane followed by 8 bit 2x2 subsampled U and V planes*/
#define		ASVL_PAF_I420				0x601
/*8 bit Y plane followed by 8 bit 1x2 subsampled U and V planes*/
#define		ASVL_PAF_I422V				0x602
/*8 bit Y plane followed by 8 bit 2x1 subsampled U and V planes*/
#define		ASVL_PAF_I422H				0x603
/*8 bit Y plane followed by 8 bit U and V planes*/
#define		ASVL_PAF_I444				0x604
/*8 bit Y plane followed by 8 bit 2x2 subsampled V and U planes*/
#define		ASVL_PAF_YV12				0x605
/*8 bit Y plane followed by 8 bit 1x2 subsampled V and U planes*/	
#define		ASVL_PAF_YV16V				0x606
/*8 bit Y plane followed by 8 bit 2x1 subsampled V and U planes*/
#define		ASVL_PAF_YV16H				0x607
/*8 bit Y plane followed by 8 bit V and U planes*/
#define		ASVL_PAF_YV24				0x608
/*8 bit Y plane only*/
#define		ASVL_PAF_GRAY				0x701
/* Float(4 bytes, litte-end): D D ... D D */ 
#define		ASVL_PAF_GRAY_FLOAT32_LE    0x702
/* Float(4 bytes, big-end): D D ... D D */ 
#define		ASVL_PAF_GRAY_FLOAT32_BE    0x703

/*8 bit Y plane followed by 8 bit 2x2 subsampled UV planes*/
#define		ASVL_PAF_NV12				0x801
/*8 bit Y plane followed by 8 bit 2x2 subsampled VU planes*/
#define		ASVL_PAF_NV21				0x802
/*8 bit Y plane followed by 8 bit 2x1 subsampled UV planes*/
#define		ASVL_PAF_LPI422H			0x803
/*8 bit Y plane followed by 8 bit 2x1 subsampled VU planes*/
#define		ASVL_PAF_LPI422H2			0x804

/*8 bit Y plane followed by 8 bit 4x4 subsampled VU planes*/
#define		ASVL_PAF_NV41				0x805

/*Negative UYVY, U0, Y0, V0, Y1*/																			
#define		ASVL_PAF_NEG_UYVY			0x901
/*Negative I420, 8 bit Y plane followed by 8 bit 2x2 subsampled U and V planes*/
#define		ASVL_PAF_NEG_I420			0x902


/*Mono UYVY, UV values are fixed, gray image in U0, Y0, V0, Y1*/
#define		ASVL_PAF_MONO_UYVY			0xa01
/*Mono I420, UV values are fixed, 8 bit Y plane followed by 8 bit 2x2 subsampled U and V planes*/
#define		ASVL_PAF_MONO_I420			0xa02

/*P8_YUYV, 8 pixels a group, Y0Y1Y2Y3Y4Y5Y6Y7U0U1U2U3V0V1V2V3*/
#define		ASVL_PAF_P8_YUYV			0xb03

/*P16_YUYV, 16*16 pixels a group, Y0Y1Y2Y3...U0U1...V0V1...*/
#define		ASVL_PAF_SP16UNIT			0xc01

#define		ASVL_PAF_DEPTH_U16			0xc02


/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  0  0  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH8_U16_MSB	0xc10

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  0  0  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_DEPTH8_U16_LSB	0xc11

/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH10_U16_MSB	0xc12

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_DEPTH10_U16_LSB	0xc13

/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH12_U16_MSB	0xc14

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define		ASVL_PAF_DEPTH12_U16_LSB	0xc15


/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH14_U16_MSB	0xc16

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define		ASVL_PAF_DEPTH14_U16_LSB	0xc17


/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH16_U16	0xc18



/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH9_U16_MSB	  0xc19

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_DEPTH9_U16_LSB	   0xc1a


/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH11_U16_MSB	  0xc1b

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0 , 
*/
#define		ASVL_PAF_DEPTH11_U16_LSB	   0xc1c

/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH13_U16_MSB	  0xc1d

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0 , 
*/
#define		ASVL_PAF_DEPTH13_U16_LSB	   0xc1e

/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_DEPTH15_U16_MSB	  0xc1f

/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0 , 
*/
#define		ASVL_PAF_DEPTH15_U16_LSB	   0xc20

/*10 bits Bayer raw data, each pixel use 10 bits memory size*/
#define     ASVL_PAF_RAW10_RGGB_10B       		   0xd01
#define     ASVL_PAF_RAW10_GRBG_10B                0xd02
#define     ASVL_PAF_RAW10_GBRG_10B                0xd03
#define     ASVL_PAF_RAW10_BGGR_10B                0xd04

/*12 bits Bayer raw data, each pixel use 12 bits memory size*/
#define     ASVL_PAF_RAW12_RGGB_12B       		   0xd05
#define     ASVL_PAF_RAW12_GRBG_12B                0xd06
#define     ASVL_PAF_RAW12_GBRG_12B                0xd07
#define     ASVL_PAF_RAW12_BGGR_12B                0xd08

/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW10_RGGB_16B        		   0xd09
#define     ASVL_PAF_RAW10_GRBG_16B                0xd0A
#define     ASVL_PAF_RAW10_GBRG_16B                0xd0B
#define     ASVL_PAF_RAW10_BGGR_16B                0xd0C

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW12_RGGB_16B		           0xd11
#define		ASVL_PAF_RAW12_GRBG_16B		           0xd12
#define		ASVL_PAF_RAW12_GBRG_16B		           0xd13
#define		ASVL_PAF_RAW12_BGGR_16B		           0xd14

/*16 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW16_RGGB_16B		           0xd21
#define		ASVL_PAF_RAW16_GRBG_16B		           0xd22
#define		ASVL_PAF_RAW16_GBRG_16B		           0xd23
#define		ASVL_PAF_RAW16_BGGR_16B		           0xd24

/*14 bits Bayer raw data, each pixel use 14 bits memory size*/
#define     ASVL_PAF_RAW14_RGGB_14B       		   0xd35
#define     ASVL_PAF_RAW14_GRBG_14B                0xd36
#define     ASVL_PAF_RAW14_GBRG_14B                0xd37
#define     ASVL_PAF_RAW14_BGGR_14B                0xd38

/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW14_RGGB_16B		           0xd41
#define		ASVL_PAF_RAW14_GRBG_16B		           0xd42
#define		ASVL_PAF_RAW14_GBRG_16B		           0xd43
#define		ASVL_PAF_RAW14_BGGR_16B		           0xd44

/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW10_RGGB_16B_MSB       	   0xd51
#define     ASVL_PAF_RAW10_GRBG_16B_MSB            0xd52
#define     ASVL_PAF_RAW10_GBRG_16B_MSB            0xd53
#define     ASVL_PAF_RAW10_BGGR_16B_MSB            0xd54

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW12_RGGB_16B_MSB	           0xd56
#define		ASVL_PAF_RAW12_GRBG_16B_MSB	           0xd57
#define		ASVL_PAF_RAW12_GBRG_16B_MSB	           0xd58
#define		ASVL_PAF_RAW12_BGGR_16B_MSB	           0xd59

/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW14_RGGB_16B_MSB	           0xd5a
#define		ASVL_PAF_RAW14_GRBG_16B_MSB	           0xd5b
#define		ASVL_PAF_RAW14_GBRG_16B_MSB	           0xd5c
#define		ASVL_PAF_RAW14_BGGR_16B_MSB	           0xd5d

/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
*/
#define     ASVL_PAF_RAW10_RGGB_16B_LSB       	   0xd61
#define     ASVL_PAF_RAW10_GRBG_16B_LSB            0xd62
#define     ASVL_PAF_RAW10_GBRG_16B_LSB            0xd63
#define     ASVL_PAF_RAW10_BGGR_16B_LSB            0xd64

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW12_RGGB_16B_LSB	           0xd66
#define		ASVL_PAF_RAW12_GRBG_16B_LSB	           0xd67
#define		ASVL_PAF_RAW12_GBRG_16B_LSB	           0xd68
#define		ASVL_PAF_RAW12_BGGR_16B_LSB	           0xd69

/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define		ASVL_PAF_RAW14_RGGB_16B_LSB	           0xd6a
#define		ASVL_PAF_RAW14_GRBG_16B_LSB	           0xd6b
#define		ASVL_PAF_RAW14_GBRG_16B_LSB	           0xd6c
#define		ASVL_PAF_RAW14_BGGR_16B_LSB	           0xd6d


/*8 bits Bayer raw data, each pixel use 1 bytes(8bits) memory size*/
/* 
  00 01 02 03 04 05 06 07
  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW8_RGGB_8B	           0xd71
#define		ASVL_PAF_RAW8_GRBG_8B	           0xd72
#define		ASVL_PAF_RAW8_GBRG_8B	           0xd73
#define		ASVL_PAF_RAW8_BGGR_8B	           0xd74

/*8 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW8_RGGB_16B_LSB 	           0xd75
#define		ASVL_PAF_RAW8_GRBG_16B_LSB 	           0xd76
#define		ASVL_PAF_RAW8_GBRG_16B_LSB 	           0xd77
#define		ASVL_PAF_RAW8_BGGR_16B_LSB 	           0xd78

/*8 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  0  0  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW8_RGGB_16B_MSB 	           0xd79
#define		ASVL_PAF_RAW8_GRBG_16B_MSB 	           0xd7a
#define		ASVL_PAF_RAW8_GBRG_16B_MSB 	           0xd7b
#define		ASVL_PAF_RAW8_BGGR_16B_MSB 	           0xd7c


/*9 bits Bayer raw data, each pixel use 9 bits memory size*/
#define     ASVL_PAF_RAW9_RGGB_9B       		 0xd81
#define     ASVL_PAF_RAW9_GRBG_9B                0xd82
#define     ASVL_PAF_RAW9_GBRG_9B                0xd83
#define     ASVL_PAF_RAW9_BGGR_9B                0xd84

/*11 bits Bayer raw data, each pixel use 11 bits memory size*/
#define     ASVL_PAF_RAW11_RGGB_11B       		   0xd85
#define     ASVL_PAF_RAW11_GRBG_11B                0xd86
#define     ASVL_PAF_RAW11_GBRG_11B                0xd87
#define     ASVL_PAF_RAW11_BGGR_11B                0xd88

/*13 bits Bayer raw data, each pixel use 13 bits memory size*/
#define     ASVL_PAF_RAW13_RGGB_13B       		   0xd89
#define     ASVL_PAF_RAW13_GRBG_13B                0xd8a
#define     ASVL_PAF_RAW13_GBRG_13B                0xd8b
#define     ASVL_PAF_RAW13_BGGR_13B                0xd8c

/*15 bits Bayer raw data, each pixel use 15 bits memory size*/
#define     ASVL_PAF_RAW15_RGGB_15B        		   0xd91
#define     ASVL_PAF_RAW15_GRBG_15B                0xd92
#define     ASVL_PAF_RAW15_GBRG_15B                0xd93
#define     ASVL_PAF_RAW15_BGGR_15B                0xd94


/*9 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW9_RGGB_16B		           0xd95
#define		ASVL_PAF_RAW9_GRBG_16B		           0xd96
#define		ASVL_PAF_RAW9_GBRG_16B		           0xd97
#define		ASVL_PAF_RAW9_BGGR_16B		           0xd98

/*11 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW11_RGGB_16B		           0xd99
#define		ASVL_PAF_RAW11_GRBG_16B		           0xd9a
#define		ASVL_PAF_RAW11_GBRG_16B		           0xd9b
#define		ASVL_PAF_RAW11_BGGR_16B		           0xd9c

/*13 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW13_RGGB_16B		           0xda1
#define		ASVL_PAF_RAW13_GRBG_16B		           0xda2
#define		ASVL_PAF_RAW13_GBRG_16B		           0xda3
#define		ASVL_PAF_RAW13_BGGR_16B		           0xda4

/*15 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW15_RGGB_16B		           0xda5
#define		ASVL_PAF_RAW15_GRBG_16B		           0xda6
#define		ASVL_PAF_RAW15_GBRG_16B		           0xda7
#define		ASVL_PAF_RAW15_BGGR_16B		           0xda8

/*9 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW9_RGGB_16B_LSB	           0xda9
#define		ASVL_PAF_RAW9_GRBG_16B_LSB	           0xdaa
#define		ASVL_PAF_RAW9_GBRG_16B_LSB	           0xdab
#define		ASVL_PAF_RAW9_BGGR_16B_LSB	           0xdac


/*11 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW11_RGGB_16B_LSB	           0xdb1
#define		ASVL_PAF_RAW11_GRBG_16B_LSB	           0xdb2
#define		ASVL_PAF_RAW11_GBRG_16B_LSB	           0xdb3
#define		ASVL_PAF_RAW11_BGGR_16B_LSB	           0xdb4


/*13 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0 , 
*/
#define		ASVL_PAF_RAW13_RGGB_16B_LSB	           0xdb5
#define		ASVL_PAF_RAW13_GRBG_16B_LSB	           0xdb6
#define		ASVL_PAF_RAW13_GBRG_16B_LSB	           0xdb7
#define		ASVL_PAF_RAW13_BGGR_16B_LSB	           0xdb8

/*15 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0 , 
*/
#define		ASVL_PAF_RAW15_RGGB_16B_LSB	           0xdb9
#define		ASVL_PAF_RAW15_GRBG_16B_LSB	           0xdba
#define		ASVL_PAF_RAW15_GBRG_16B_LSB	           0xdbb
#define		ASVL_PAF_RAW15_BGGR_16B_LSB	           0xdbc

/*9 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW9_RGGB_16B_MSB       	  0xdd1
#define     ASVL_PAF_RAW9_GRBG_16B_MSB            0xdd2
#define     ASVL_PAF_RAW9_GBRG_16B_MSB            0xdd3
#define     ASVL_PAF_RAW9_BGGR_16B_MSB            0xdd4

/*11 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW11_RGGB_16B_MSB       	   0xdd5
#define     ASVL_PAF_RAW11_GRBG_16B_MSB            0xdd6
#define     ASVL_PAF_RAW11_GBRG_16B_MSB            0xdd7
#define     ASVL_PAF_RAW11_BGGR_16B_MSB            0xdd8

/*13 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW13_RGGB_16B_MSB	           0xdd9
#define		ASVL_PAF_RAW13_GRBG_16B_MSB	           0xdda
#define		ASVL_PAF_RAW13_GBRG_16B_MSB	           0xddb
#define		ASVL_PAF_RAW13_BGGR_16B_MSB	           0xddc

/*15 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW15_RGGB_16B_MSB	           0xde1
#define		ASVL_PAF_RAW15_GRBG_16B_MSB	           0xde2
#define		ASVL_PAF_RAW15_GBRG_16B_MSB	           0xde3
#define		ASVL_PAF_RAW15_BGGR_16B_MSB	           0xde4


/*10 bits gray raw data, each pixel use 10 bits memory size*/
#define     ASVL_PAF_RAW10_GRAY_10B       		   0xe01

/*12 bits gray raw data, each pixel use 12 bits memory size*/
#define     ASVL_PAF_RAW12_GRAY_12B       		   0xe11

/*14 bits gray raw data, each pixel use 14 bits memory size*/
#define     ASVL_PAF_RAW14_GRAY_14B       		   0xe21

/*16 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW16_GRAY_16B       		   0xe31

/*10 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW10_GRAY_16B        		   0xe81

/*10 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW10_GRAY_16B_MSB        		   0xe82

/*10 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
*/
#define     ASVL_PAF_RAW10_GRAY_16B_LSB        		   0xe83


/*11 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW11_GRAY_16B        		   0xe88

/*11 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW11_GRAY_16B_MSB        		   0xe89

/*11 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0 , 
*/
#define     ASVL_PAF_RAW11_GRAY_16B_LSB        		   0xe8a


/*12 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW12_GRAY_16B        		   0xe91

/*12 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW12_GRAY_16B_MSB    		   0xe92

/*12 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define     ASVL_PAF_RAW12_GRAY_16B_LSB   		   0xe93



/*13 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW13_GRAY_16B        		   0xe98

/*13 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW13_GRAY_16B_MSB    		   0xe99

/*13 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0 , 
*/
#define     ASVL_PAF_RAW13_GRAY_16B_LSB   		   0xe9a

/*14 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW14_GRAY_16B        		   0xea1

/*14 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW14_GRAY_16B_MSB        	   0xea2

/*14 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define     ASVL_PAF_RAW14_GRAY_16B_LSB            0xea3


/*15 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW15_GRAY_16B        		   0xea8

/*15 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW15_GRAY_16B_MSB        	   0xea9

/*15 bits gray raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0 , 
*/
#define     ASVL_PAF_RAW15_GRAY_16B_LSB            0xeaa


/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes*/
/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y , 
  ....
  0  0  0  0  0  0  U  U  U  U  U  U  U  U  U  U , 
  0  0  0  0  0  0  V  V  V  V  V  V  V  V  V  V ,
  ....
*/
#define		ASVL_PAF_P010_MSB			0xf01


/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes
 Y Y Y Y Y Y Y Y
 Y Y Y Y Y Y Y Y
 Y Y Y Y Y Y Y Y
 Y Y Y Y Y Y Y Y
 U V U V U V U V 
 U V U V U V U V 
*/
/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  0  0  0  0  0  0 , 
  ....
  U  U  U  U  U  U  U  U  U  U  0  0  0  0  0  0 , 
  V  V  V  V  V  V  V  V  V  V  0  0  0  0  0  0 ,
  ....
*/
#define		ASVL_PAF_P010_LSB			0xf02


/*12 bit Y plane followed by 12 bit 2x2 subsampled UV planes*/
/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y , 
  ....
  0  0  0  0  U  U  U  U  U  U  U  U  U  U  U  U , 
  0  0  0  0  V  V  V  V  V  V  V  V  V  V  V  V ,
  ....
*/
#define		ASVL_PAF_P012_MSB			0xf03

/*12 bit Y plane followed by 12 bit 2x2 subsampled UV planes*/
/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  0  0  0  0 , 
  ....
  U  U  U  U  U  U  U  U  U  U  U  U  0  0  0  0 , 
  V  V  V  V  V  V  V  V  V  V  V  V  0  0  0  0 ,
  ....
*/
#define		ASVL_PAF_P012_LSB			0xf04

/*14 bit Y plane followed by 14 bit 2x2 subsampled UV planes*/
/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y , 
  ....
  0  0  U  U  U  U  U  U  U  U  U  U  U  U  U  U , 
  0  0  V  V  V  V  V  V  V  V  V  V  V  V  V  V ,
  ....
*/
#define		ASVL_PAF_P014_MSB			0xf05

/*14 bit Y plane followed by 14 bit 2x2 subsampled UV planes*/
/* 
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  0  0 , 
  ....
  U  U  U  U  U  U  U  U  U  U  U  U  U  U  0  0 , 
  V  V  V  V  V  V  V  V  V  V  V  V  V  V  0  0 ,
  ....
*/
#define		ASVL_PAF_P014_LSB			0xf06

/* pixel distribution for ASVL_PAF_YUV420P10_MSB, ASVL_PAF_YUV420P10_LSB
 Y Y Y Y Y Y Y Y
 Y Y Y Y Y Y Y Y
 Y Y Y Y Y Y Y Y
 Y Y Y Y Y Y Y Y
 U U U U U U U U
 V V V V V V V V
 */
/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes*/
/*
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y ,
  ....
  0  0  0  0  0  0  U  U  U  U  U  U  U  U  U  U ,
  0  0  0  0  0  0  V  V  V  V  V  V  V  V  V  V ,
  ....
*/
#define		ASVL_PAF_YUV420P10_MSB			0xf11

/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes*/
/*
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  0  0  0  0  0  0 ,
  ....
  U  U  U  U  U  U  U  U  U  U  0  0  0  0  0  0 ,
  V  V  V  V  V  V  V  V  V  V  0  0  0  0  0  0 ,
  ....
*/
#define		ASVL_PAF_YUV420P10_LSB			0xf12

/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes*/
/*
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y ,
  ....
  0  0  0  0  U  U  U  U  U  U  U  U  U  U  U  U ,
  0  0  0  0  V  V  V  V  V  V  V  V  V  V  V  V ,
  ....
*/
#define		ASVL_PAF_YUV420P12_MSB			0xf13

/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes*/
/*
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  Y  0  0  0  0 ,
  ....
  U  U  U  U  U  U  U  U  U  U  U  U  0  0  0  0 ,
  V  V  V  V  V  V  V  V  V  V  V  V  0  0  0  0 ,
  ....
*/
#define		ASVL_PAF_YUV420P12_LSB			0xf14

/*10 bit Y plane followed by 10 bit 2x2 subsampled UV planes
 Address: LSB-->MSB
 |<--padding to 128bit(16 bytes)*n by [0]-->|
 Y Y Y Y Y Y Y Y ...... Y Y Y Y [0]
 Y Y Y Y Y Y Y Y ...... Y Y Y Y [0]
 Y Y Y Y Y Y Y Y ...... Y Y Y Y [0]
 Y Y Y Y Y Y Y Y ...... Y Y Y Y [0]
 U V U V U V U V ...... U V U V [0]
 U V U V U V U V ...... U V U V [0]

  By Bits:
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 ...
  Y0 Y0 Y0 Y0 Y0 Y0 Y0 Y0 Y0 Y0 Y1 Y1 Y1 Y1 Y1 Y1 ..., 
  ....
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 ...,
  U0 U0 U0 U0 U0 U0 U0 U0 U0 U0 V0 V0 V0 V0 V0 V0 ..., 
  ....
*/
#define		ASVL_PAF_P010_PACKED			0xf41



/* Define from QC: 
   	pi32Pitch[0] is 64 alignment of (i32Width+2)/3)*4;
	pi32Pitch[1] is 64 alignment of (i32Width+2)/3)*4;
	ppu8Plane[0] size is pi32Pitch[0] * (((i32Height+3)/4)*4); 
	ppu8Plane[1] size is pi32Pitch[1] * (((i32Height>>1+3)/4)*4); 
   */
#define		ASVL_PAF_NV21_TP10			    0x1001
#define		ASVL_PAF_NV12_TP10			    0x1002


/* 2 planes, and pitch is equal to the length of plane by byte. 4kB alignment. */
#define		ASVL_PAF_UBWC_TP10			    0x1010

/* Todo for detail. 4kB alignment. */
#define		ASVL_PAF_UBWC_NV12			    0x1020


/*8 bits QuadBayer raw data, each pixel use 1 bytes(8bits) memory size*/
/* 
  00 01 02 03 04 05 06 07
  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW8_RGGB_8B	               0x1101
#define		ASVL_PAF_QUADRAW8_GRBG_8B	               0x1102
#define		ASVL_PAF_QUADRAW8_GBRG_8B	               0x1103
#define		ASVL_PAF_QUADRAW8_BGGR_8B	               0x1104

/*8 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_QUADRAW8_RGGB_16B_LSB 	           0x1105
#define		ASVL_PAF_QUADRAW8_GRBG_16B_LSB 	           0x1106
#define		ASVL_PAF_QUADRAW8_GBRG_16B_LSB 	           0x1107
#define		ASVL_PAF_QUADRAW8_BGGR_16B_LSB 	           0x1108

/*8 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  0  0  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW8_RGGB_16B_MSB 	           0x1109
#define		ASVL_PAF_QUADRAW8_GRBG_16B_MSB 	           0x110a
#define		ASVL_PAF_QUADRAW8_GBRG_16B_MSB 	           0x110b
#define		ASVL_PAF_QUADRAW8_BGGR_16B_MSB 	           0x110c

/*10 bits QuadBayer raw data, each pixel use 10 bits memory size*/
#define     ASVL_PAF_QUADRAW10_RGGB_10B       		   0x1111
#define     ASVL_PAF_QUADRAW10_GRBG_10B                0x1112
#define     ASVL_PAF_QUADRAW10_GBRG_10B                0x1113
#define     ASVL_PAF_QUADRAW10_BGGR_10B                0x1114

/*10 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
*/
#define     ASVL_PAF_QUADRAW10_RGGB_16B_LSB       	   0x1115
#define     ASVL_PAF_QUADRAW10_GRBG_16B_LSB            0x1116
#define     ASVL_PAF_QUADRAW10_GBRG_16B_LSB            0x1117
#define     ASVL_PAF_QUADRAW10_BGGR_16B_LSB            0x1118

/*10 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_QUADRAW10_RGGB_16B_MSB       	   0x1119
#define     ASVL_PAF_QUADRAW10_GRBG_16B_MSB            0x111a
#define     ASVL_PAF_QUADRAW10_GBRG_16B_MSB            0x111b
#define     ASVL_PAF_QUADRAW10_BGGR_16B_MSB            0x111c

/*12 bits QuadBayer raw data, each pixel use 12 bits memory size*/
#define     ASVL_PAF_QUADRAW12_RGGB_12B       		   0x1121
#define     ASVL_PAF_QUADRAW12_GRBG_12B                0x1122
#define     ASVL_PAF_QUADRAW12_GBRG_12B                0x1123
#define     ASVL_PAF_QUADRAW12_BGGR_12B                0x1124

/*12 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define		ASVL_PAF_QUADRAW12_RGGB_16B_LSB	       0x1125
#define		ASVL_PAF_QUADRAW12_GRBG_16B_LSB	       0x1126
#define		ASVL_PAF_QUADRAW12_GBRG_16B_LSB	       0x1127
#define		ASVL_PAF_QUADRAW12_BGGR_16B_LSB	       0x1128

/*12 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW12_RGGB_16B_MSB	       0x1129
#define		ASVL_PAF_QUADRAW12_GRBG_16B_MSB	       0x112a
#define		ASVL_PAF_QUADRAW12_GBRG_16B_MSB	       0x112b
#define		ASVL_PAF_QUADRAW12_BGGR_16B_MSB	       0x112c

/*14 bits QuadBayer raw data, each pixel use 14 bits memory size*/
#define     ASVL_PAF_QUADRAW14_RGGB_14B       		   0x1131
#define     ASVL_PAF_QUADRAW14_GRBG_14B                0x1132
#define     ASVL_PAF_QUADRAW14_GBRG_14B                0x1133
#define     ASVL_PAF_QUADRAW14_BGGR_14B                0x1134

/*14 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define		ASVL_PAF_QUADRAW14_RGGB_16B_LSB	           0x1135
#define		ASVL_PAF_QUADRAW14_GRBG_16B_LSB	           0x1136
#define		ASVL_PAF_QUADRAW14_GBRG_16B_LSB	           0x1137
#define		ASVL_PAF_QUADRAW14_BGGR_16B_LSB	           0x1138

/*14 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW14_RGGB_16B_MSB	           0x1139
#define		ASVL_PAF_QUADRAW14_GRBG_16B_MSB	           0x113a
#define		ASVL_PAF_QUADRAW14_GBRG_16B_MSB	           0x113b
#define		ASVL_PAF_QUADRAW14_BGGR_16B_MSB	           0x113c

/*16 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_QUADRAW16_RGGB_16B		           0x1141
#define		ASVL_PAF_QUADRAW16_GRBG_16B		           0x1142
#define		ASVL_PAF_QUADRAW16_GBRG_16B		           0x1143
#define		ASVL_PAF_QUADRAW16_BGGR_16B		           0x1144


/*11 bits QuadBayer raw data, each pixel use 11 bits memory size*/
#define     ASVL_PAF_QUADRAW11_RGGB_11B       		   0x1151
#define     ASVL_PAF_QUADRAW11_GRBG_11B                0x1152
#define     ASVL_PAF_QUADRAW11_GBRG_11B                0x1153
#define     ASVL_PAF_QUADRAW11_BGGR_11B                0x1154

/*11 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0 , 
*/
#define		ASVL_PAF_QUADRAW11_RGGB_16B_LSB	           0x1155
#define		ASVL_PAF_QUADRAW11_GRBG_16B_LSB	           0x1156
#define		ASVL_PAF_QUADRAW11_GBRG_16B_LSB	           0x1157
#define		ASVL_PAF_QUADRAW11_BGGR_16B_LSB	           0x1158

/*11 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW11_RGGB_16B_MSB	           0x1159
#define		ASVL_PAF_QUADRAW11_GRBG_16B_MSB	           0x115a
#define		ASVL_PAF_QUADRAW11_GBRG_16B_MSB	           0x115b
#define		ASVL_PAF_QUADRAW11_BGGR_16B_MSB	           0x115c


/*13 bits QuadBayer raw data, each pixel use 13 bits memory size*/
#define     ASVL_PAF_QUADRAW13_RGGB_13B       		   0x1161
#define     ASVL_PAF_QUADRAW13_GRBG_13B                0x1162
#define     ASVL_PAF_QUADRAW13_GBRG_13B                0x1163
#define     ASVL_PAF_QUADRAW13_BGGR_13B                0x1164

/*13 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0 , 
*/
#define		ASVL_PAF_QUADRAW13_RGGB_16B_LSB	           0x1165
#define		ASVL_PAF_QUADRAW13_GRBG_16B_LSB	           0x1166
#define		ASVL_PAF_QUADRAW13_GBRG_16B_LSB	           0x1167
#define		ASVL_PAF_QUADRAW13_BGGR_16B_LSB	           0x1168

/*13 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW13_RGGB_16B_MSB	           0x1169
#define		ASVL_PAF_QUADRAW13_GRBG_16B_MSB	           0x116a
#define		ASVL_PAF_QUADRAW13_GBRG_16B_MSB	           0x116b
#define		ASVL_PAF_QUADRAW13_BGGR_16B_MSB	           0x116c


/*15 bits QuadBayer raw data, each pixel use 15 bits memory size*/
#define     ASVL_PAF_QUADRAW15_RGGB_15B       		   0x1171
#define     ASVL_PAF_QUADRAW15_GRBG_15B                0x1172
#define     ASVL_PAF_QUADRAW15_GBRG_15B                0x1173
#define     ASVL_PAF_QUADRAW15_BGGR_15B                0x1174

/*15 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0 , 
*/
#define		ASVL_PAF_QUADRAW15_RGGB_16B_LSB	           0x1175
#define		ASVL_PAF_QUADRAW15_GRBG_16B_LSB	           0x1176
#define		ASVL_PAF_QUADRAW15_GBRG_16B_LSB	           0x1177
#define		ASVL_PAF_QUADRAW15_BGGR_16B_LSB	           0x1178

/*15 bits QuadBayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_QUADRAW15_RGGB_16B_MSB	           0x1179
#define		ASVL_PAF_QUADRAW15_GRBG_16B_MSB	           0x117a
#define		ASVL_PAF_QUADRAW15_GBRG_16B_MSB	           0x117b
#define		ASVL_PAF_QUADRAW15_BGGR_16B_MSB	           0x117c

/*31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 */

/* LSB
   0000 0000 R R ... R 0000 0000 G G ... G 0000 0000 B B ... B 
*/
#define		ASVL_PAF_RGB_B8G8R8_48B_LSB		                      0x1201
/* MSB   
   R R ... R 0000 0000 G G ... G 0000 0000 B B ... B 0000 0000 
*/
#define		ASVL_PAF_RGB_B8G8R8_48B_MSB		                      0x1202

/* R R ... R G G ... G B B ... B */
#define		ASVL_PAF_RGB_B10G10R10_30B		                      0x1203
/* LSB
   0000 00 R R ... R 0000 00 G G ... G 0000 00 B B ... B 
*/
#define		ASVL_PAF_RGB_B10G10R10_48B_LSB		                  0x1204
/* MSB                                                            
   R R ... R 00 0000 G G ... G 00 0000 B B ... B 00 0000                   
*/                                                                
#define		ASVL_PAF_RGB_B10G10R10_48B_MSB		                  0x1205
                                                                  
/* R R ... R G G ... G B B ... B */                               
#define		ASVL_PAF_RGB_B12G12R12_36B		                      0x1206
/* LSB                                                            
   0000 R R ... R 0000 G G ... G 0000 B B ... B                   
*/                                                                
#define		ASVL_PAF_RGB_B12G12R12_48B_LSB		                  0x1207
/* MSB                                                            
   R R ... R 0000 G G ... G 0000 B B ... B 0000                   
*/                                                                
#define		ASVL_PAF_RGB_B12G12R12_48B_MSB		                  0x1208

/* R R ... R G G ... G B B ... B */                               
#define		ASVL_PAF_RGB_B14G14R14_42B		                      0x1209
/* LSB                                                            
   00 R R ... R 00 G G ... G 00 B B ... B                   
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_48B_LSB		                  0x120a
/* MSB                                                            
   R R ... R 00 G G ... G 00 B B ... B 00                   
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_48B_MSB		                  0x120b

/* R R ... R G G ... G B B ... B */                               
#define		ASVL_PAF_RGB_B16G16R16_48B		                      0x120c

/* Float(4 bytes, litte-end as default): R R ... R G G ... G B B ... B */ 
#define		ASVL_PAF_RGB_BGR_FLOAT32		                      0x120d

/* Int32(4 bytes, litte-end as default): R R ... R G G ... G B B ... B */ 
#define		ASVL_PAF_RGB_BGR_INT32		                          0x120e

/* LSB
   0000 0000 B B ... B 0000 0000 G G ... G 0000 0000 R R ... R
*/
#define		ASVL_PAF_RGB_R8G8B8_48B_LSB		                      0x1211
/* MSB   
   B B ... B 0000 0000 G G ... G 0000 0000 R R ... R 0000 0000  
*/
#define		ASVL_PAF_RGB_R8G8B8_48B_MSB		                      0x1212

/* B B ... B G G ... G R R ... R */
#define		ASVL_PAF_RGB_R10G10B10_30B		                      0x1213
/* LSB
   0000 00 B B ... B 0000 00 G G ... G 0000 00 R R ... R 
*/
#define		ASVL_PAF_RGB_R10G10B10_48B_LSB		                  0x1214
/* MSB                                                            
   B B ... B 00 0000 G G ... G 00 0000 R R ... R 00 0000                     
*/                                                                
#define		ASVL_PAF_RGB_R10G10B10_48B_MSB		                  0x1215
                                                                  
/* B B ... B G G ... G R R ... R */                               
#define		ASVL_PAF_RGB_R12G12B12_36B		                      0x1216
/* LSB                                                            
   0000 B B ... B 0000 G G ... G 0000 R R ... R                   
*/                                                                
#define		ASVL_PAF_RGB_R12G12B12_48B_LSB		                  0x1217
/* MSB                                                            
   B B ... B 0000 G G ... G 0000 R R ... R 0000                    
*/                                                                
#define		ASVL_PAF_RGB_R12G12B12_48B_MSB		                  0x1218

/* B B ... B G G ... G R R ... R */                               
#define		ASVL_PAF_RGB_R14G14B14_42B		                      0x1219
/* LSB                                                            
   00 B B ... B 00 G G ... G 00 R R ... R                   
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_48B_LSB		                  0x121a
/* MSB                                                            
   B B ... B 00 G G ... G 00 R R ... R 00                    
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_48B_MSB		                  0x121b

/* B B ... B G G ... G R R ... R */                               
#define		ASVL_PAF_RGB_R16G16B16_48B		                      0x121c

/* Float(4 bytes, litte-end as default): B B ... B G G ... G R R ... R */    
#define		ASVL_PAF_RGB_RGB_FLOAT32	                          0x121d

/* Int32(4 bytes, litte-end as default): B B ... B G G ... G R R ... R */    
#define		ASVL_PAF_RGB_RGB_INT32		                          0x121e



/* R R ... R G G ... G B B ... B */
#define		ASVL_PAF_RGB_B9G9R9_27B		                           0x1221
/* LSB
   0000 000 R R ... R 0000 000 G G ... G 0000 000 B B ... B 
*/
#define		ASVL_PAF_RGB_B9G9R9_48B_LSB		                       0x1222
/* MSB                                                            
   R R ... R 000 0000 G G ... G 000 0000 B B ... B 000 0000                   
*/                                                                
#define		ASVL_PAF_RGB_B9G9R9_48B_MSB		                       0x1223

/* R R ... R G G ... G B B ... B */
#define		ASVL_PAF_RGB_B11G11R11_33B		                       0x1224
/* LSB
   0000 0 R R ... R 0000 0 G G ... G 0000 0 B B ... B 
*/
#define		ASVL_PAF_RGB_B11G11R11_48B_LSB		                   0x1225
/* MSB                                                            
   R R ... R 0 0000 G G ... G 0 0000 B B ... B 0 0000                   
*/                                                                
#define		ASVL_PAF_RGB_B11G11R11_48B_MSB		                   0x1226

/* R R ... R G G ... G B B ... B */
#define		ASVL_PAF_RGB_B13G13R13_39B		                       0x1227
/* LSB
   000 R R ... R 000 G G ... G 000 B B ... B 
*/
#define		ASVL_PAF_RGB_B13G13R13_48B_LSB		                   0x1228
/* MSB                                                            
   R R ... R 000 G G ... G 000 B B ... B 000                   
*/                                                                
#define		ASVL_PAF_RGB_B13G13R13_48B_MSB		                   0x1229

/* R R ... R G G ... G B B ... B */
#define		ASVL_PAF_RGB_B15G15R15_45B		                       0x122a
/* LSB
   0 R R ... R 0 G G ... G 0 B B ... B 
*/
#define		ASVL_PAF_RGB_B15G15R15_48B_LSB		                   0x122b
/* MSB                                                            
   R R ... R 0 G G ... G 0 B B ... B 0                   
*/                                                                
#define		ASVL_PAF_RGB_B15G15R15_48B_MSB		                   0x122c



/* B B ... B G G ... G R R ... R */
#define		ASVL_PAF_RGB_R9G9B9_27B		                           0x1231
/* LSB                                                             
   0000 000 B B ... B 0000 000 G G ... G 0000 000 R R ... R           
*/                                                                 
#define		ASVL_PAF_RGB_R9G9B9_48B_LSB		                       0x1232
/* MSB                                                                 
   B B ... B 000 0000 G G ... G 000 0000 R R ... R 000 0000                          
*/                                                                     
#define		ASVL_PAF_RGB_R9G9B9_48B_MSB		                       0x1233
                                                                  
/* B B ... B G G ... G R R ... R */
#define		ASVL_PAF_RGB_R11G11B11_33B		                       0x1234
/* LSB                                                             
   0000 0 B B ... B 0000 0 G G ... G 0000 0 R R ... R           
*/                                                                 
#define		ASVL_PAF_RGB_R11G11B11_48B_LSB		                   0x1235
/* MSB                                                                 
   B B ... B 0 0000 G G ... G 0 0000 R R ... R 0 0000                          
*/                                                                     
#define		ASVL_PAF_RGB_R11G11B11_48B_MSB		                   0x1236
                                                                 
/* B B ... B G G ... G R R ... R */
#define		ASVL_PAF_RGB_R13G13B13_39B		                       0x1237
/* LSB                                                             
   000 B B ... B 000 G G ... G 000 R R ... R           
*/                                                                 
#define		ASVL_PAF_RGB_R13G13B13_48B_LSB		                   0x1238
/* MSB                                                                 
   B B ... B 000 G G ... G 000 R R ... R 000                          
*/                                                                     
#define		ASVL_PAF_RGB_R13G13B13_48B_MSB		                   0x1239
                                                                
/* B B ... B G G ... G R R ... R */
#define		ASVL_PAF_RGB_R15G15B15_45B		                       0x123a
/* LSB                                                             
   0 B B ... B 0 G G ... G 0 R R ... R           
*/                                                                 
#define		ASVL_PAF_RGB_R15G15B15_48B_LSB		                   0x123b
/* MSB                                                                 
   B B ... B 0 G G ... G 0 R R ... R 0                          
*/                                                                     
#define		ASVL_PAF_RGB_R15G15B15_48B_MSB		                   0x123c




/* LSB,Planer(3xPlanes)
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
   0000 0000 R R ... R - 0000 0000 R R  
   0000 0000 G G ... G - 0000 0000 G G 
   0000 0000 B B ... B - 0000 0000 B B   
*/
#define		ASVL_PAF_RGB_R8G8B8_PLANER_48B_LSB                            0x1301
/* MSB,Planer(3xPlanes)
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
   R R ... R 0000 0000 - R R ... R 0000 0000  
   G G ... G 0000 0000 - G G ... G 0000 0000  
   B B ... B 0000 0000 - B B ... B 0000 0000  
*/
#define		ASVL_PAF_RGB_R8G8B8_PLANER_48B_MSB		                      0x1302

/* Planer(3xPlanes)
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
   R R ... R - R R ... R  
   G G ... G - G G ... G  
   B B ... B - B B ... B  
*/
#define		ASVL_PAF_RGB_R10G10B10_PLANER_30B		                      0x1303
/* LSB,Planer(3xPlanes)  
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 00 R R ... R - 0000 00 R R ... R
   0000 00 G G ... G - 0000 00 G G ... G
   0000 00 B B ... B - 0000 00 B B ... B
*/
#define		ASVL_PAF_RGB_R10G10B10_PLANER_48B_LSB		                  0x1304
/* MSB,Planer(3xPlanes)      
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00                                                         
   R R ... R 00 0000 - R R ... R 00 0000 
   G G ... G 00 0000 - G G ... G 00 0000 
   B B ... B 00 0000 - B B ... B 00 0000                   
*/                                                                
#define		ASVL_PAF_RGB_R10G10B10_PLANER_48B_MSB		                  0x1305
                                                                  
/* Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/                               
#define		ASVL_PAF_RGB_R12G12B12_PLANER_36B		                      0x1306
/* LSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 R R ... R - 0000 R R ... R
   0000 G G ... G - 0000 G G ... G
   0000 B B ... B - 0000 B B ... B                  
*/                                                                
#define		ASVL_PAF_RGB_R12G12B12_PLANER_48B_LSB		                  0x1307
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 0000 - R R ... R 0000
   G G ... G 0000 - G G ... G 0000
   B B ... B 0000 - B B ... B 0000                  
*/                                                                
#define		ASVL_PAF_RGB_R12G12B12_PLANER_48B_MSB		                  0x1308

/* Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/                               
#define		ASVL_PAF_RGB_R14G14B14_PLANER_42B		                      0x1309
/* LSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   00 R R ... R - 00 R R ... R
   00 G G ... G - 00 G G ... G
   00 B B ... B - 00 B B ... B                  
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_PLANER_48B_LSB		                  0x130a
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 00 - R R ... R 00
   G G ... G 00 - G G ... G 00
   B B ... B 00 - B B ... B 00                  
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_PLANER_48B_MSB		                  0x130b

/* Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/                               
#define		ASVL_PAF_RGB_R16G16B16_PLANER_48B		                      0x130c

/* Float(4 bytes, litte-end as default): Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/ 
#define		ASVL_PAF_RGB_RGB_PLANER_FLOAT32		                         0x130d

/* Int32(4 bytes, litte-end as default):Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/ 
#define		ASVL_PAF_RGB_RGB_PLANER_INT32		                          0x130e

/* LSB,Planer(3xPlanes)   
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 0000 B B ... B - 0000 0000 B B ... B
   0000 0000 G G ... G - 0000 0000 G G ... G
   0000 0000 R R ... R - 0000 0000 R R ... R
*/
#define		ASVL_PAF_RGB_B8G8R8_PLANER_48B_LSB		                      0x1311
/* MSB,Planer(3xPlanes)      
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 0000 0000 - B B ... B 0000 0000
   G G ... G 0000 0000 - G G ... G 0000 0000
   R R ... R 0000 0000 - R R ... R 0000 0000 
*/
#define		ASVL_PAF_RGB_B8G8R8_PLANER_48B_MSB		                      0x1312

/* Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/
#define		ASVL_PAF_RGB_B10G10R10_PLANER_30B		                      0x1313
/* LSB,Planer(3xPlanes)   
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 00 B B ... B - 0000 00 B B ... B
   0000 00 G G ... G - 0000 00 G G ... G
   0000 00 R R ... R - 0000 00 R R ... R
*/
#define		ASVL_PAF_RGB_B10G10R10_PLANER_48B_LSB		                  0x1314
/* MSB,Planer(3xPlanes)
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 00 0000 - B B ... B 00 0000 
   G G ... G 00 0000 - G G ... G 00 0000 
   R R ... R 00 0000 - R R ... R 00 0000                     
*/                                                                
#define		ASVL_PAF_RGB_B10G10R10_PLANER_48B_MSB		                  0x1315
                                                                  
/* Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/                               
#define		ASVL_PAF_RGB_B12G12R12_PLANER_36B		                      0x1316
/* LSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 B B ... B - 0000 B B ... B
   0000 G G ... G - 0000 G G ... G
   0000 R R ... R - 0000 R R ... R                  
*/                                                                
#define		ASVL_PAF_RGB_B12G12R12_PLANER_48B_LSB		                  0x1317
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 0000 - B B ... B 0000
   G G ... G 0000 - G G ... G 0000
   R R ... R 0000 - R R ... R 0000                   
*/                                                                
#define		ASVL_PAF_RGB_B12G12R12_PLANER_48B_MSB		                  0x1318

/* Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/                               
#define		ASVL_PAF_RGB_B14G14R14_PLANER_42B		                      0x1319
/* LSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   00 B B ... B - 00 B B ... B
   00 G G ... G - 00 G G ... G
   00 R R ... R - 00 R R ... R                  
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_PLANER_48B_LSB		                  0x131a
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 00 - B B ... B 00 
   G G ... G 00 - G G ... G 00 
   R R ... R 00 - R R ... R 00                    
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_PLANER_48B_MSB		                  0x131b

/* Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/                               
#define		ASVL_PAF_RGB_B16G16R16_PLANER_48B		                      0x131c

/* Float(4 bytes, litte-end as default): Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/    
#define		ASVL_PAF_RGB_BGR_PLANER_FLOAT32	                             0x131d

/* Int32(4 bytes, litte-end as default): Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/    
#define		ASVL_PAF_RGB_BGR_PLANER_INT32		                          0x131e



/* Planer(3xPlanes) 
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/
#define		ASVL_PAF_RGB_R9G9B9_PLANER_27B		                           0x1321
/* LSB,Planer(3xPlanes)   
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 000 R R ... R - 0000 000 R R ... R 
   0000 000 G G ... G - 0000 000 G G ... G 
   0000 000 B B ... B - 0000 000 B B ... B 
*/
#define		ASVL_PAF_RGB_R9G9B9_PLANER_48B_LSB		                       0x1322
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 000 0000 - R R ... R 000 0000
   G G ... G 000 0000 - G G ... G 000 0000
   B B ... B 000 0000 - B B ... B 000 0000                  
*/                                                                
#define		ASVL_PAF_RGB_R9G9B9_PLANER_48B_MSB		                       0x1323

/* Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/
#define		ASVL_PAF_RGB_R11G11B11_PLANER_33B		                       0x1324
/* LSB,Planer(3xPlanes)   
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 0 R R ... R - 0000 0 R R ... R 
   0000 0 G G ... G - 0000 0 G G ... G 
   0000 0 B B ... B - 0000 0 B B ... B 
*/
#define		ASVL_PAF_RGB_R11G11B11_PLANER_48B_LSB		                   0x1325
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 0 0000 - R R ... R 0 0000 
   G G ... G 0 0000 - G G ... G 0 0000 
   B B ... B 0 0000 - B B ... B 0 0000                   
*/                                                                
#define		ASVL_PAF_RGB_R11G11B11_PLANER_48B_MSB		                   0x1326

/* Planer(3xPlanes)    
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/
#define		ASVL_PAF_RGB_R13G13B13_PLANER_39B		                       0x1327
/* LSB,Planer(3xPlanes)   
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   000 R R ... R - 000 R R ... R
   000 G G ... G - 000 G G ... G
   000 B B ... B - 000 B B ... B
*/
#define		ASVL_PAF_RGB_R13G13B13_PLANER_48B_LSB		                   0x1328
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 000 - R R ... R 000 
   G G ... G 000 - G G ... G 000 
   B B ... B 000 - B B ... B 000                   
*/                                                                
#define		ASVL_PAF_RGB_R13G13B13_PLANER_48B_MSB		                   0x1329

/* Planer(3xPlanes)
   R R ... R - R R ... R 
   G G ... G - G G ... G 
   B B ... B - B B ... B 
*/
#define		ASVL_PAF_RGB_R15G15B15_PLANER_45B		                       0x132a
/* LSB,Planer(3xPlanes)   
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0 R R ... R - 0 R R ... R
   0 G G ... G - 0 G G ... G
   0 B B ... B - 0 B B ... B
*/
#define		ASVL_PAF_RGB_R15G15B15_PLANER_48B_LSB		                   0x132b
/* MSB,Planer(3xPlanes)                                                               
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 0 - R R ... R 0 
   G G ... G 0 - G G ... G 0 
   B B ... B 0 - B B ... B 0                   
*/                                                                
#define		ASVL_PAF_RGB_R15G15B15_PLANER_48B_MSB		                   0x132c



/* Planer(3xPlanes)
   B B ... B - B B ... B 
   G G ... G - G G ... G 
   R R ... R - R R ... R 
*/
#define		ASVL_PAF_RGB_B9G9R9_PLANER_27B		                           0x1331
/* LSB,Planer(3xPlanes)                                                                
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 000 B B ... B - 0000 000 B B ... B
   0000 000 G G ... G - 0000 000 G G ... G
   0000 000 R R ... R - 0000 000 R R ... R          
*/                                                                 
#define		ASVL_PAF_RGB_B9G9R9_PLANER_48B_LSB		                       0x1332
/* MSB,Planer(3xPlanes)                                                                    
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 000 0000 - B B ... B 000 0000
   G G ... G 000 0000 - G G ... G 000 0000
   R R ... R 000 0000 - R R ... R 000 0000                         
*/                                                                     
#define		ASVL_PAF_RGB_B9G9R9_PLANER_48B_MSB		                       0x1333
                                                                  
/* Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/
#define		ASVL_PAF_RGB_B11G11R11_PLANER_33B		                       0x1334
/* LSB,Planer(3xPlanes)                                                                
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0000 0 B B ... B - 0000 0 B B ... B
   0000 0 G G ... G - 0000 0 G G ... G
   0000 0 R R ... R - 0000 0 R R ... R          
*/                                                                 
#define		ASVL_PAF_RGB_B11G11R11_PLANER_48B_LSB		                   0x1335
/* MSB,Planer(3xPlanes)                                                                    
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 0 0000 - B B ... B 0 0000 
   G G ... G 0 0000 - G G ... G 0 0000 
   R R ... R 0 0000 - R R ... R 0 0000                          
*/                                                                     
#define		ASVL_PAF_RGB_B11G11R11_PLANER_48B_MSB		                   0x1336
                                                                 
/* Planer(3xPlanes)
   B B ... B - B B ... B 
   G G ... G - G G ... G 
   R R ... R - R R ... R 
*/
#define		ASVL_PAF_RGB_B13G13R13_PLANER_39B		                       0x1337
/* LSB,Planer(3xPlanes)                                                                
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   000 B B ... B - 000 B B ... B
   000 G G ... G - 000 G G ... G
   000 R R ... R - 000 R R ... R          
*/                                                                 
#define		ASVL_PAF_RGB_B13G13R13_PLANER_48B_LSB		                   0x1338
/* MSB,Planer(3xPlanes)                                                                    
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 000 - B B ... B 000
   G G ... G 000 - G G ... G 000
   R R ... R 000 - R R ... R 000                         
*/                                                                     
#define		ASVL_PAF_RGB_B13G13R13_PLANER_48B_MSB		                   0x1339
                                                                
/* Planer(3xPlanes)
   B B ... B - B B ... B
   G G ... G - G G ... G
   R R ... R - R R ... R
*/
#define		ASVL_PAF_RGB_B15G15R15_PLANER_45B		                       0x133a
/* LSB,Planer(3xPlanes)                                                                
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   0 B B ... B - 0 B B ... B
   0 G G ... G - 0 G G ... G
   0 R R ... R - 0 R R ... R          
*/                                                                 
#define		ASVL_PAF_RGB_B15G15R15_PLANER_48B_LSB		                   0x133b
/* MSB,Planer(3xPlanes)                                                                    
   16bit:15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 0 - B B ... B 0
   G G ... G 0 - G G ... G 0
   R R ... R 0 - R R ... R 0                        
*/                                                                     
#define		ASVL_PAF_RGB_B15G15R15_PLANER_48B_MSB		                   0x133c




/* LSB                                                            
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   00000000 00000000 00 R R ... R 00000000 00000000 00 G G ... G 00000000 00000000 00 B B ... B   
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_96B_LSB		                  0x1402
/* MSB                                                            
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 00 00000000 00000000 G G ... G 00 00000000 00000000 B B ... B 00 00000000 00000000   
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_96B_MSB		                  0x1403

/* LSB      
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   00000000 00000000 00 B B ... B 00000000 00000000 00 G G ... G 00000000 00000000 00 R R ... R    
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_96B_LSB		                  0x1405
/* MSB                                                            
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 00 00000000 00000000 G G ... G 00 00000000 00000000 R R ... R 00 00000000 00000000    
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_96B_MSB		                  0x1406


/* LSB,Planer(3xPlanes)                                                               
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   00000000 00000000 00 R R ... R - 00000000 00000000 00 R R ... R
   00000000 00000000 00 G G ... G - 00000000 00000000 00 G G ... G
   00000000 00000000 00 B B ... B - 00000000 00000000 00 B B ... B                  
*/                                                                
#define		ASVL_PAF_RGB_R14G14B14_PLANER_96B_LSB		                  0x1408
/* MSB,Planer(3xPlanes)                                                               
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   R R ... R 00 00000000 00000000 - R R ... R 00 00000000 00000000
   G G ... G 00 00000000 00000000 - G G ... G 00 00000000 00000000
   B B ... B 00 00000000 00000000 - B B ... B 00 00000000 00000000                 
*/                                                                

#define		ASVL_PAF_RGB_R14G14B14_PLANER_96B_MSB		                  0x1409

/* LSB,Planer(3xPlanes)                                                               
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   00000000 00000000 00 B B ... B - 00000000 00000000 00 B B ... B
   00000000 00000000 00 G G ... G - 00000000 00000000 00 G G ... G
   00000000 00000000 00 R R ... R - 00000000 00000000 00 R R ... R                  
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_PLANER_96B_LSB		                  0x140b
/* MSB,Planer(3xPlanes)                                                               
   32bit:31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00 
   B B ... B 00 00000000 00000000 - B B ... B 00 00000000 00000000 
   G G ... G 00 00000000 00000000 - G G ... G 00 00000000 00000000
   R R ... R 00 00000000 00000000 - R R ... R 00 00000000 00000000 
*/                                                                
#define		ASVL_PAF_RGB_B14G14R14_PLANER_96B_MSB		                  0x140c



/*10 bits Raw data for MSC, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW10_MSC3x3_16B_LSB	           0x1601

/*10 bits Raw data for MSC, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW10_MSC3x3_16B_MSB	           0x1602

/*10 bits Raw data for MSC, each pixel use 10 bits memory size*/
#define		ASVL_PAF_RAW10_MSC3x3_10B	               0x1603


/*12 bits Raw data for MSC, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW12_MSC3x3_16B_LSB	           0x1605

/*12 bits Raw data for MSC, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW12_MSC3x3_16B_MSB	           0x1606

/*12 bits Raw data for MSC, each pixel use 12 bits memory size*/
#define		ASVL_PAF_RAW12_MSC3x3_12B	               0x1607

/*14 bits Raw data for MSC, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define		ASVL_PAF_RAW14_MSC3x3_16B_LSB	           0x1609

/*14 bits Raw data for MSC, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW14_MSC3x3_16B_MSB	           0x160a

/*14 bits Raw data for MSC, each pixel use 14 bits memory size*/
#define		ASVL_PAF_RAW14_MSC3x3_14B	               0x160b


/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
  Pattern BGRG: 
      BGRG 
	  GIGI
	  RGBR
	  GIGI
*/
#define		ASVL_PAF_RAW10_BGRG_IR_16B_LSB	           0x1701  

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW12_BGRG_IR_16B_LSB	           0x1705 
   
/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define		ASVL_PAF_RAW14_BGRG_IR_16B_LSB	           0x1709 
   
/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW10_BGRG_IR_16B_MSB             0x1711
/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW12_BGRG_IR_16B_MSB             0x1715
/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW14_BGRG_IR_16B_MSB             0x1719




/*10 bits Bayer raw data, each pixel use 10 bits memory size*/
#define     ASVL_PAF_RAW10_RYYB_10B       		   0x2d01
#define     ASVL_PAF_RAW10_YRBY_10B                0x2d02
#define     ASVL_PAF_RAW10_YBRY_10B                0x2d03
#define     ASVL_PAF_RAW10_BYYR_10B                0x2d04

/*12 bits Bayer raw data, each pixel use 12 bits memory size*/
#define     ASVL_PAF_RAW12_RYYB_12B       		   0x2d05
#define     ASVL_PAF_RAW12_YRBY_12B                0x2d06
#define     ASVL_PAF_RAW12_YBRY_12B                0x2d07
#define     ASVL_PAF_RAW12_BYYR_12B                0x2d08

/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define     ASVL_PAF_RAW10_RYYB_16B        		   0x2d09
#define     ASVL_PAF_RAW10_YRBY_16B                0x2d0A
#define     ASVL_PAF_RAW10_YBRY_16B                0x2d0B
#define     ASVL_PAF_RAW10_BYYR_16B                0x2d0C

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW12_RYYB_16B		           0x2d11
#define		ASVL_PAF_RAW12_YRBY_16B		           0x2d12
#define		ASVL_PAF_RAW12_YBRY_16B		           0x2d13
#define		ASVL_PAF_RAW12_BYYR_16B		           0x2d14

/*16 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW16_RYYB_16B		           0x2d21
#define		ASVL_PAF_RAW16_YRBY_16B		           0x2d22
#define		ASVL_PAF_RAW16_YBRY_16B		           0x2d23
#define		ASVL_PAF_RAW16_BYYR_16B		           0x2d24

/*14 bits Bayer raw data, each pixel use 14 bits memory size*/
#define     ASVL_PAF_RAW14_RYYB_14B       		   0x2d35
#define     ASVL_PAF_RAW14_YRBY_14B                0x2d36
#define     ASVL_PAF_RAW14_YBRY_14B                0x2d37
#define     ASVL_PAF_RAW14_BYYR_14B                0x2d38

/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
#define		ASVL_PAF_RAW14_RYYB_16B		           0x2d41
#define		ASVL_PAF_RAW14_YRBY_16B		           0x2d42
#define		ASVL_PAF_RAW14_YBRY_16B		           0x2d43
#define		ASVL_PAF_RAW14_BYYR_16B		           0x2d44

/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  0  0  D  D  D  D  D  D  D  D  D  D , 
*/
#define     ASVL_PAF_RAW10_RYYB_16B_MSB       	   0x2d51
#define     ASVL_PAF_RAW10_YRBY_16B_MSB            0x2d52
#define     ASVL_PAF_RAW10_YBRY_16B_MSB            0x2d53
#define     ASVL_PAF_RAW10_BYYR_16B_MSB            0x2d54

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  0  0  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW12_RYYB_16B_MSB	           0x2d56
#define		ASVL_PAF_RAW12_YRBY_16B_MSB	           0x2d57
#define		ASVL_PAF_RAW12_YBRY_16B_MSB	           0x2d58
#define		ASVL_PAF_RAW12_BYYR_16B_MSB	           0x2d59

/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* MSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  0  0  D  D  D  D  D  D  D  D  D  D  D  D  D  D , 
*/
#define		ASVL_PAF_RAW14_RYYB_16B_MSB	           0x2d5a
#define		ASVL_PAF_RAW14_YRBY_16B_MSB	           0x2d5b
#define		ASVL_PAF_RAW14_YBRY_16B_MSB	           0x2d5c
#define		ASVL_PAF_RAW14_BYYR_16B_MSB	           0x2d5d

/*10 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  0  0  0  0  0  0 , 
*/
#define     ASVL_PAF_RAW10_RYYB_16B_LSB       	   0x2d61
#define     ASVL_PAF_RAW10_YRBY_16B_LSB            0x2d62
#define     ASVL_PAF_RAW10_YBRY_16B_LSB            0x2d63
#define     ASVL_PAF_RAW10_BYYR_16B_LSB            0x2d64

/*12 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  0  0  0  0 , 
*/
#define		ASVL_PAF_RAW12_RYYB_16B_LSB	           0x2d66
#define		ASVL_PAF_RAW12_YRBY_16B_LSB	           0x2d67
#define		ASVL_PAF_RAW12_YBRY_16B_LSB	           0x2d68
#define		ASVL_PAF_RAW12_BYYR_16B_LSB	           0x2d69

/*14 bits Bayer raw data, each pixel use 2 bytes(16bits) memory size*/
/* LSB
  00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15
  D  D  D  D  D  D  D  D  D  D  D  D  D  D  0  0 , 
*/
#define		ASVL_PAF_RAW14_RYYB_16B_LSB	           0x2d6a
#define		ASVL_PAF_RAW14_YRBY_16B_LSB	           0x2d6b
#define		ASVL_PAF_RAW14_YBRY_16B_LSB	           0x2d6c
#define		ASVL_PAF_RAW14_BYYR_16B_LSB	           0x2d6d


/*Define the image format space*/		
typedef struct __tag_ASVL_OFFSCREEN
{
	MUInt32	u32PixelArrayFormat;
	MInt32	i32Width;
	MInt32	i32Height;
	MUInt8*	ppu8Plane[4];
	MInt32	pi32Pitch[4];
}ASVLOFFSCREEN, *LPASVLOFFSCREEN;

/*Define the SDK Version infos. This is the template!!!*/		
typedef struct __tag_ASVL_VERSION
{
	    MLong lCodebase;             	// Codebase version number 
	    MLong lMajor;                		// major version number 
	    MLong lMinor;                		// minor version number
	    MLong lBuild;                		// Build version number, increasable only
	    const MChar *Version;        	// version in string form
	    const MChar *BuildDate;      	// latest build Date
	    const MChar *CopyRight;      	// copyright 
}ASVL_VERSION;
const ASVL_VERSION *ASVL_GetVersion();

#ifdef __cplusplus
}
#endif

#endif /*__ASVL_OFFSCREEN_H__*/
