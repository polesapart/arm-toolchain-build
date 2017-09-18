#!/bin/bash
# Compila o toolchain para compilação cruzada, tendo como alvo a arquitetura
# arm-none-eabi.

GCC_VERSION=7.1.0
BINUTILS_VERSION=2.28
NEWLIB_VERSION=2.5.0.20170519
NEWLIB_OPTS="--enable-newlib-reent-small --enable-newlib-multithread --disable-newlib-supplied-syscalls"
#INSIGHT_VERSION=7.0
GDB_VERSION=7.12.1

ARCH=arm-none-eabi
#BINUTILS_NFP="--with-float=soft"
GCC_NFP="--with-float=soft"

MAKE="make"
MKDIR="mkdir -p"
MULTIMAKE="$MAKE -j4"

prefix=/usr/local/${ARCH}-${GCC_VERSION}

SOURCEDIR=`dirname $0`
SOURCEDIR=`(cd $SOURCEDIR && /bin/pwd)`

DOWNDIR=${SOURCEDIR}/download

BUILDDIR=${SOURCEDIR}/build-${ARCH}-${GCC_VERSION}

export CCACHE_DIR=${BUILDDIR}/ccache
export CCACHE_COMPRESS=1
export CCACHE_BASEDIR=${BUILDDIR}
export CCACHE_TEMPDIR=/tmp
set -x -e

${MKDIR} $BUILDDIR
cd $BUILDDIR


export PATH="${PATH}:${prefix}/bin"

ccache=/usr/lib/ccache
if [ -d "$ccache" ] && echo $PATH | grep -vq "$ccache" ; then
   export PATH="${ccache}:${PATH}"
fi



if [ ! -d binutils-${BINUTILS_VERSION} ]; then
	tar xvf ${DOWNDIR}/binutils-${BINUTILS_VERSION}.tar.*
  if [ -f ${DOWNDIR}/binutils-${BINUTILS_VERSION}.patch.gz ]; then
          zcat ${DOWNDIR}/binutils-${BINUTILS_VERSION}.patch.gz | (cd binutils-${BINUTILS_VERSION} && patch --verbose -p1)
  fi
fi
${MKDIR} binutils-${BINUTILS_VERSION}-build
cd binutils-${BINUTILS_VERSION}-build
CFLAGS='-O2' ../binutils-${BINUTILS_VERSION}/configure --target=${ARCH} --prefix=${prefix} --enable-interwork --enable-multilib \
	${BINUTILS_NFP} --enable-long-long --enable-plugins --enable-gold --enable-lto
${MULTIMAKE} all
${MULTIMAKE} install
cd ..

if [ ! -d gcc-${GCC_VERSION} ]; then
  tar xvf ${DOWNDIR}/gcc-${GCC_VERSION}.tar.*
  [ -f ${DOWNDIR}/gcc-${GCC_VERSION}.patch.gz ] && zcat ${DOWNDIR}/gcc-${GCC_VERSION}.patch.gz | (cd gcc-${GCC_VERSION} && patch --verbose -p1)
fi

if [ "$ARCH" = "arm-none-eabi"  ]; then
	multilib_config=gcc-${GCC_VERSION}/gcc/config/arm/t-arm-elf
	cp -a $multilib_config ${multilib_config}.old
	cat <<"EOF" >$multilib_config
MULTILIB_OPTIONS     = marm/mthumb
MULTILIB_DIRNAMES    = arm thumb
MULTILIB_EXCEPTIONS  =
MULTILIB_MATCHES     =

#MULTILIB_OPTIONS     += mcpu=fa526/mcpu=fa626/mcpu=fa606te/mcpu=fa626te/mcpu=fmp626/mcpu=fa726te
#MULTILIB_DIRNAMES    += fa526 fa626 fa606te fa626te fmp626 fa726te
#MULTILIB_EXCEPTIONS  += *mthumb*/*mcpu=fa526 *mthumb*/*mcpu=fa626

MULTILIB_OPTIONS      += march=armv7
MULTILIB_DIRNAMES     += thumb2
MULTILIB_EXCEPTIONS   += march=armv7* marm/*march=armv7*
MULTILIB_MATCHES      += march?armv7=march?armv7-a
MULTILIB_MATCHES      += march?armv7=march?armv7-r
MULTILIB_MATCHES      += march?armv7=march?armv7-m
MULTILIB_MATCHES      += march?armv7=mcpu?cortex-a8
MULTILIB_MATCHES      += march?armv7=mcpu?cortex-r4
MULTILIB_MATCHES      += march?armv7=mcpu?cortex-m3
MULTILIB_MATCHES      += march?armv7=mcpu?cortex-m4


# Not quite true.  We can support hard-vfp calling in Thumb2, but how do we
# express that here?  Also, we really need architecture v5e or later
# (mcrr etc).
MULTILIB_OPTIONS       += mfloat-abi=hard
MULTILIB_DIRNAMES      += fpu
MULTILIB_EXCEPTIONS    += *mthumb/*mfloat-abi=hard*
#MULTILIB_EXCEPTIONS    += *mcpu=fa526/*mfloat-abi=hard*
#MULTILIB_EXCEPTIONS    += *mcpu=fa626/*mfloat-abi=hard*


# MULTILIB_OPTIONS    += mcpu=ep9312
# MULTILIB_DIRNAMES   += ep9312
# MULTILIB_EXCEPTIONS += *mthumb/*mcpu=ep9312*
# 	
# MULTILIB_OPTIONS     += mlittle-endian/mbig-endian
# MULTILIB_DIRNAMES    += le be
# MULTILIB_MATCHES     += mbig-endian=mbe mlittle-endian=mle
# 
# MULTILIB_OPTIONS    += mfloat-abi=hard/mfloat-abi=soft
# MULTILIB_DIRNAMES   += fpu soft
# MULTILIB_EXCEPTIONS += *mthumb/*mfloat-abi=hard*
# 
MULTILIB_OPTIONS    += mno-thumb-interwork/mthumb-interwork
MULTILIB_DIRNAMES   += normal interwork
# 
# MULTILIB_OPTIONS    += fno-leading-underscore/fleading-underscore
# MULTILIB_DIRNAMES   += elf under
# 
# MULTILIB_OPTIONS    += mcpu=arm7
# MULTILIB_DIRNAMES   += nofmult
# MULTILIB_EXCEPTIONS += *mthumb*/*mcpu=arm7*
# # Note: the multilib_exceptions matches both -mthumb and
# # -mthumb-interwork
# #
# # We have to match all the arm cpu variants which do not have the
# # multiply instruction and treat them as if the user had specified
# # -mcpu=arm7.  Note that in the following the ? is interpreted as
# # an = for the purposes of matching command line options.
# # FIXME: There ought to be a better way to do this.
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm7d
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm7di
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm70
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm700
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm700i
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm710
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm710c
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm7100
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm7500
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm7500fe
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm6
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm60
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm600
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm610
# MULTILIB_MATCHES    += mcpu?arm7=mcpu?arm620

LIB1ASMSRC = arm/lib1funcs.asm
LIB1ASMFUNCS += _udivsi3 _divsi3 _umodsi3 _modsi3 _dvmd_tls _bb_init_func \
	_call_via_rX _interwork_call_via_rX \
	_lshrdi3 _ashrdi3 _ashldi3 \
	_arm_negdf2 _arm_addsubdf3 _arm_muldivdf3 _arm_cmpdf2 _arm_unorddf2 \
	_arm_fixdfsi _arm_fixunsdfsi \
	_arm_truncdfsf2 _arm_negsf2 _arm_addsubsf3 _arm_muldivsf3 \
	_arm_cmpsf2 _arm_unordsf2 _arm_fixsfsi _arm_fixunssfsi \
	_arm_floatdidf _arm_floatdisf _arm_floatundidf _arm_floatundisf \
	_clzsi2 _clzdi2

# We want fine grained libraries, so use the new code to build the
# floating point emulation libraries.
FPBIT = fp-bit.c
DPBIT = dp-bit.c

fp-bit.c: $(srcdir)/config/fp-bit.c
	echo '#define FLOAT' > fp-bit.c
	echo '#ifndef __ARMEB__' >> fp-bit.c
	echo '#define FLOAT_BIT_ORDER_MISMATCH' >> fp-bit.c
	echo '#endif' >> fp-bit.c
	cat $(srcdir)/config/fp-bit.c >> fp-bit.c

dp-bit.c: $(srcdir)/config/fp-bit.c
	echo '#ifndef __ARMEB__' > dp-bit.c
	echo '#define FLOAT_BIT_ORDER_MISMATCH' >> dp-bit.c
	echo '#define FLOAT_WORD_ORDER_MISMATCH' >> dp-bit.c
	echo '#endif' >> dp-bit.c
	cat $(srcdir)/config/fp-bit.c >> dp-bit.c



EXTRA_MULTILIB_PARTS = crtbegin.o crtend.o crti.o crtn.o

# If EXTRA_MULTILIB_PARTS is not defined above then define EXTRA_PARTS here
# EXTRA_PARTS = crtbegin.o crtend.o crti.o crtn.o

LIBGCC = stmp-multilib
INSTALL_LIBGCC = install-multilib

# Currently there is a bug somewhere in GCC's alias analysis
# or scheduling code that is breaking _fpmul_parts in fp-bit.c.
# Disabling function inlining is a workaround for this problem.
TARGET_LIBGCC2_CFLAGS = -Dinhibit_libc -fno-inline

# Assemble startup files.
$(T)crti.o: $(srcdir)/config/arm/crti.asm $(GCC_PASSES)
	$(GCC_FOR_TARGET) $(GCC_CFLAGS) $(MULTILIB_CFLAGS) $(INCLUDES) \
	-c -o $(T)crti.o -x assembler-with-cpp $(srcdir)/config/arm/crti.asm

$(T)crtn.o: $(srcdir)/config/arm/crtn.asm $(GCC_PASSES)
	$(GCC_FOR_TARGET) $(GCC_CFLAGS) $(MULTILIB_CFLAGS) $(INCLUDES) \
	-c -o $(T)crtn.o -x assembler-with-cpp $(srcdir)/config/arm/crtn.asm
EOF

fi

if [ ! -d "newlib-${NEWLIB_VERSION}" ]; then
	tar xvf ${DOWNDIR}/newlib-${NEWLIB_VERSION}.tar.*
fi

${MKDIR} gcc-${GCC_VERSION}-build
(cd gcc-${GCC_VERSION} && rm -f  libgloss && ln -s ../newlib-${NEWLIB_VERSION}/libgloss libgloss)
(cd gcc-${GCC_VERSION} && rm -f  newlib && ln -s ../newlib-${NEWLIB_VERSION}/newlib newlib)
cd gcc-${GCC_VERSION}-build
../gcc-${GCC_VERSION}/configure --target=${ARCH} --prefix=${prefix} \
  --enable-interwork --enable-languages="c,c++" --with-newlib ${GCC_NFP}  \
  --enable-long-long --enable-gold --enable-plugin  --enable-decimal-float=yes \
  --enable-fixed-point ${NEWLIB_OPTS}
                    
${MULTIMAKE} all-gcc
${MULTIMAKE} install-gcc

#cd ..
#
#${MKDIR} newlib-${NEWLIB_VERSION}-build
#cd newlib-${NEWLIB_VERSION}-build
#../newlib-${NEWLIB_VERSION}/configure --target=${ARCH} --prefix=${prefix} --enable-interwork --enable-multilib ${GCC_NFP} --enable-long-long ${NEWLIB_OPTS}
#${MULTIMAKE} all
#${MAKE} install
#cd ..

#cd gcc-${GCC_VERSION}-build
${MULTIMAKE} all
${MAKE} install
cd ..

if [ -n "${INSIGHT_VERSION}" ]; then
 tar xvf ${DOWNDIR}/insight-${INSIGHT_VERSION}.tar.*
 if [ -f ${DOWNDIR}/insight-${INSIGHT_VERSION}.patch.bz2 ] ; then
    bunzip2 -c ${DOWNDIR}/insight-${INSIGHT_VERSION}.patch.bz2 | \
     ( cd insight-${INSIGHT_VERSION} ;  patch --verbose -p0)
 fi
 ${MKDIR} insight-${INSIGHT_VERSION}-build
 cd insight-${INSIGHT_VERSION}-build
 ../insight-${INSIGHT_VERSION}/configure --target=${ARCH} --prefix=${prefix} --enable-interwork --enable-multilib ${GCC_NFP} --enable-long-long
 ${MULTIMAKE}
 # Corrige o potencial problema na instalacao do insight.
 rm -rfv ${prefix}/share/itk*
 #mkdir -p ${prefix}/share/itk3.2
 # Os makefiles do insight estao bugados, ignoramos erros de instalacao.
 #${MAKE} -i install
 ${MAKE} install
else
 tar xvf ${DOWNDIR}/gdb-${GDB_VERSION}.tar.*
 if [ -f ${DOWNDIR}/gdb-${GDB_VERSION}.patch.bz2 ] ; then
    bunzip2 -c ${DOWNDIR}/gdb-${GDB_VERSION}.patch.bz2 | \
     ( cd gdb-${GDB_VERSION} ;  patch --verbose -p0)
 fi
 ${MKDIR} gdb-${GDB_VERSION}-build
 cd gdb-${GDB_VERSION}-build
 ../gdb-${GDB_VERSION}/configure --target=${ARCH} --prefix=${prefix} --enable-interwork --enable-multilib ${GCC_NFP} --enable-long-long
 ${MULTIMAKE}
 ${MAKE} install

fi

# Cleanup na arvore final.
echo "Efetuando limpeza na arvore de desenvolvimento"
cd ${prefix}
# Essas tralhas aceleram um pouco a compilação em c++, mas ocupam muito espaço.
#find -type d -name '*.gch' -print0 | xargs -0 rm -rf
# O processo de instalacao cria uns hardlinks quebrados. Criamos links simbolicos.
(cd arm-none-eabi/bin && for i in * ; do rm $i ; ln -vfs ../../bin/arm-none-eabi-$i $i ; done)
# Remove simbolos desnecessarios dos binarios.
(find bin libexec/gcc/arm-none-eabi -type f | xargs file | grep 'ELF.*xecutable.*not stripped' | cut -d: -f1 | xargs strip -v ) || true
# Remove outras tralhas desnecessarias
rm -rf include info lib/*.a man share/locale

echo "All Done!"

