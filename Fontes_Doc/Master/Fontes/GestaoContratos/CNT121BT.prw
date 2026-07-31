#include "totvs.ch"

/*/{Protheus.doc} CNT121BT
Ponto de entrada utilizado para adicionar botao de reenvio manual do
workflow de aprovacao de Medicao de Contrato na browse de Medicoes
(CNTA121).
@type function
@author Equipe DSSolucoes
@since 06/07/2026
@return Nil
/*/
User Function CNT121BT()

	AAdd(aRotina, {"Reenvio Workflow", "U_CAWFMD01", 0, 4})

Return
