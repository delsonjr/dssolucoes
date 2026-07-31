#include "totvs.ch"

/*/{Protheus.doc} CTA100MNU
Ponto de entrada utilizado para adicionar botao de reenvio manual do
workflow de aprovacao de Contrato na browse de Contratos (CNTA300).
@type function
@author Equipe DSSolucoes
@since 06/07/2026
@return Nil
/*/
User Function CTA100MNU()

	AAdd(aRotina, {"Reenvio Workflow", "U_CAWFCT01", 0, 4})

Return
