#!/bin/bash
# Use getopt instead of getopts for long options

set -e

OPTS=`getopt -o o: --long output-dir:,bam:,genome-reference:,out-prefix:,selector:,maxDepth:,maxFractionOfReadsWithLowMAPQ:,maxLowMAPQ:,minBaseQuality:,minMappingQuality:,minDepth:,minDepthForLowMAPQ:,extra-arguments:,out-script:,standalone, -n 'callableLoci.sh'  -- "$@"`

if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

#echo "$OPTS"
eval set -- "$OPTS"

MYDIR="$( cd "$( dirname "$0" )" && pwd )"

timestamp=$( date +"%Y-%m-%d_%H-%M-%S_%N" )

maxDepth=-1
maxFractionOfReadsWithLowMAPQ=0.1
maxLowMAPQ=1
minBaseQuality=20
minMappingQuality=10
minDepth=4
minDepthForLowMAPQ=10


while true; do
    case "$1" in
        -o | --output-dir )
            case "$2" in
                "") shift 2 ;;
                *)  outdir=$2 ; shift 2 ;;
            esac ;;
            
        --bam )
            case "$2" in
                "") shift 2 ;;
                *)  bamFile=$2 ; shift 2 ;;
            esac ;;

        --out-prefix )
            case "$2" in
                "") shift 2 ;;
                *)  outPrefix=$2 ; shift 2 ;;
            esac ;;

        --genome-reference )
            case "$2" in
                "") shift 2 ;;
                *)  HUMAN_REFERENCE=$2 ; shift 2 ;;
            esac ;;

        --maxDepth )
            case "$2" in
                "") shift 2 ;;
                *)  maxDepth=$2 ; shift 2 ;;
            esac ;;

        --maxFractionOfReadsWithLowMAPQ )
            case "$2" in
                "") shift 2 ;;
                *)  maxFractionOfReadsWithLowMAPQ=$2 ; shift 2 ;;
            esac ;;

        --maxLowMAPQ )
            case "$2" in
                "") shift 2 ;;
                *)  maxLowMAPQ=$2 ; shift 2 ;;
            esac ;;

        --minBaseQuality )
            case "$2" in
                "") shift 2 ;;
                *)  minBaseQuality=$2 ; shift 2 ;;
            esac ;;

        --minMappingQuality )
            case "$2" in
                "") shift 2 ;;
                *)  minMappingQuality=$2 ; shift 2 ;;
            esac ;;

        --minDepth )
            case "$2" in
                "") shift 2 ;;
                *)  minDepth=$2 ; shift 2 ;;
            esac ;;

        --minDepthForLowMAPQ )
            case "$2" in
                "") shift 2 ;;
                *)  minDepthForLowMAPQ=$2 ; shift 2 ;;
            esac ;;

        --selector )
            case "$2" in
                "") shift 2 ;;
                *)  SELECTOR=$2 ; shift 2 ;;
            esac ;;

        --extra-arguments )
            case "$2" in
                "") shift 2 ;;
                *)  extra_arguments=$2 ; shift 2 ;;
            esac ;;

        --out-script )
            case "$2" in
                "") shift 2 ;;
                *)  out_script_name=$2 ; shift 2 ;;
            esac ;;

        --standalone )
            standalone=1 ; shift ;;

        -- ) shift; break ;;
        * ) break ;;
    esac
done

logdir=${outdir}/logs
mkdir -p ${logdir}

if [[ ${out_script_name} ]]
then
    out_script="${out_script_name}"
else
    out_script="${logdir}/callableLoci.${timestamp}.cmd"    
fi


if [[ $standalone ]]
then
    echo "#!/bin/bash" > $out_script
    echo "" >> $out_script
    echo "#$ -o ${logdir}" >> $out_script
    echo "#$ -e ${logdir}" >> $out_script
    echo "#$ -S /bin/bash" >> $out_script
    echo '#$ -l h_vmem=8G' >> $out_script
    echo 'set -e' >> $out_script
fi

echo "" >> $out_script
echo 'echo -e "Start at `date +"%Y/%m/%d %H:%M:%S"`" 1>&2' >> $out_script
echo "" >> $out_script

if [[ ${SELECTOR} ]]
then
    selector_text="-L /mnt/${SELECTOR}"
fi

echo "docker run --rm -v /:/mnt -u $UID broadinstitute/gatk3:3.8-0 \\" >> $out_script
echo "java -Xmx8g -jar /usr/GenomeAnalysisTK.jar \\" >> $out_script
echo "-T CallableLoci \\" >> $out_script
echo "-R /mnt/${HUMAN_REFERENCE} \\" >> $out_script
echo "-I /mnt/${bamFile} \\" >> $out_script
echo "--maxDepth ${maxDepth} \\" >> $out_script
echo "--maxFractionOfReadsWithLowMAPQ ${maxFractionOfReadsWithLowMAPQ} \\" >> $out_script
echo "--maxLowMAPQ ${maxLowMAPQ} \\" >> $out_script
echo "--minBaseQuality ${minBaseQuality} \\" >> $out_script
echo "--minMappingQuality ${minMappingQuality} \\" >> $out_script
echo "--minDepth ${minDepth} \\" >> $out_script
echo "--minDepthForLowMAPQ ${minDepthForLowMAPQ} \\" >> $out_script
echo "--summary /mnt/${outdir}/${outPrefix}.summary \\" >> $out_script
echo "${selector_text} \\" >> $out_script
echo "${extra_arguments} \\" >> $out_script
echo "-o /mnt/${outdir}/${outPrefix}.Callable.bed" >> $out_script

echo "" >> $out_script

echo 'echo -e "Done at `date +"%Y/%m/%d %H:%M:%S"`" 1>&2' >> $out_script
