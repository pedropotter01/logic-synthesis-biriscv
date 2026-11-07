#!/bin/bash

LOG_OUT="sweep_results.csv"
echo "BHT,BTB,RAS,Total_Branches,Mispredicts,Miss_Rate_Percent,BTB_Errors" > $LOG_OUT

echo "Iniciando simulacao das 200 combinacoes no Xcelium..."

calc_w() {
  local val=$1
  local w=0
  while [ $val -gt 1 ]; do
    val=$((val / 2))
    w=$((w + 1))
  done
  echo $w
}

for RAS in 2 4 8 16 32; do
  RAS_W=$(calc_w $RAS)
  for BTB in 4 8 16 32 64; do
    BTB_W=$(calc_w $BTB)
    for BHT in 16 32 64 128 256 512 1024 2048; do
      BHT_W=$(calc_w $BHT)

      xrun -64bit -timescale 1ns/1ps \
           +define+BHT_VAL=$BHT \
           +define+BHT_W_VAL=$BHT_W \
           +define+BTB_VAL=$BTB \
           +define+BTB_W_VAL=$BTB_W \
           +define+RAS_VAL=$RAS \
           +define+RAS_W_VAL=$RAS_W \
           biriscv_npc.v tb_npc_eval.v \
           -nolog \
           > sim_temp.log 2>&1

      RAW_LINE=$(grep "RESULT:" sim_temp.log)

      if [ -z "$RAW_LINE" ]; then
        echo "FALHA em BHT=$BHT BTB=$BTB RAS=$RAS. Verifique sim_temp.log:"
        cat sim_temp.log
        exit 1
      fi
      
      TOTAL=$(echo "$RAW_LINE" | awk '{print $2}' | cut -d'=' -f2)
      MISP=$(echo "$RAW_LINE"  | awk '{print $3}' | cut -d'=' -f2)
      RATE=$(echo "$RAW_LINE"  | awk '{print $4}' | tr -d '()%')
      BTB_ERR=$(echo "$RAW_LINE" | awk '{print $5}' | cut -d'=' -f2)

      echo "$BHT,$BTB,$RAS,$TOTAL,$MISP,$RATE,$BTB_ERR" >> $LOG_OUT
      echo "OK -> BHT=$BHT | BTB=$BTB | RAS=$RAS | Total=$TOTAL | Erro: $RATE%"

    done
  done
done

rm -f sim_temp.log
echo "Varredura concluida. Arquivo $LOG_OUT gerado com sucesso."
