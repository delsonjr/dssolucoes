#include "PROTHEUS.CH"
#include "TBICONN.CH"


/*/{Protheus.doc} WFPE007   
Permite customizar a mensagem de processamento do WF por link. 
@type function
@author Delson Junior Antunes
@since 06/07/2026
/*/

User Function WFPE007()
	Local cHTML 		:= ""
	Local plSuccess		:= ParamIXB[1]
	Local pcMessage  	:= ParamIXB[2]
	Local pcProcessID  	:= ParamIXB[3]

	cHTML += '<html>'
	cHTML += '<head>'
	cHTML += '<meta http-equiv="Content-Type" content="text/html;charset=UTF-8">'
	cHTML += '<title>Workflow Protheus</title>'
	cHTML += '</head>'
	cHTML += '<body style="font-family:sans-serif;padding:0px 40px;margin:0px;border-top:7px solid #FFFFFF">'
	cHTML += '    <table bgcolor="#ffffff" style="width:100%; display: block;" cellpadding="0" cellspacing="10" border="0">'
	cHTML += '        <tr style="height: 80px;">'
	cHTML += '            <!-- Header -->
	cHTML += '            <td style="background-color: #FFFFFF;width: 100%; padding: 0px 20px">
	cHTML += '                <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcnzMClDFoaE2XBiJneRnl39FUXjSypRfCbFEiHOmN1g&s=10"
	cHTML += '                width="180" alt="EMPRESA">
	cHTML += '            </td>
	cHTML += '        </tr>
	cHTML += '        <tr>
	cHTML += '            <td colspan="2" style="border-left: 3px solid #FFFFFF;padding: 20px;">

	cHTML += '                <p>Documento enviado para processamento no sistema!</p>

	If ( plSuccess )
		//-------------------------------------------------------------------
		// Mensagem em formato HTML para sucesso no processamento.
		//-------------------------------------------------------------------
		cHTML += '                <p>Documento enviado para processamento no sistema!</p>
		cHTML += '<br>'
		cHTML += pcMessage
	Else
		//-------------------------------------------------------------------
		// Mensagem em formato HTML para falha no processamento.
		//-------------------------------------------------------------------
		cHTML += '                <p>Falha no processamento!!</p>
		cHTML += '<br>'
		cHTML += pcMessage
	EndIf

	cHTML += '            </td>
	cHTML += '        </tr>
	cHTML += '    </table>
	cHTML += '</body>
	cHTML += '</html>


Return cHTML
