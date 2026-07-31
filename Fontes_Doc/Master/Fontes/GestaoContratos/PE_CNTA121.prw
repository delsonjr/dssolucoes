#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "Parmtype.ch"
#Include "FWMVCDEF.CH"
/*/
{Protheus.doc} CNTA121
PONTO DE ENTRADA - MVC: Manutencao das Medicoes de Contratos
@type function
@author Delson Junior Antunes
@since 06/07/2026
/*/
User Function CNTA121()

	Local aParam     := ParamIXB
	Local xRet       := .T.
	Local oObj       := ""
	Local cIdPonto   := ""
	Local cIdModel   := ""
	Local lIsGrid    := .F.

	If aParam <> Nil
		oObj     := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid  := ( Len(aParam) > 3 )
		If cIdPonto == "MODELPOS" //.and. ncnta121aux == 0


			// --> Workflow de aprovacao por e-mail apos a confirmacao da inclusao da medicao
		ElseIf cIdPonto == "MODELCOMMITNTTS"
			If INCLUI
				//	U_CAWFMDChk(oObj)
			EndIf
		EndIf
	EndIf

Return xRet
