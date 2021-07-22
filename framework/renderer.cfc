component {

	public any function init() {
		return this;
	}

	public any function renderBuilder() {
		var builder = { };
		structAppend( builder, {
			// allow type and data to be overridden just for completeness
			type : function( v ) {
				if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
				request._fw1.renderData.type = v;
				return builder;
			},
			data : function( v ) {
				if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
				request._fw1.renderData.data = v;
				return builder;
			},
			header : function( h, v ) {
				if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
				if ( !structKeyExists( request._fw1.renderData, 'headers' ) ) {
					request._fw1.renderData.headers = [ ];
				}
				arrayAppend( request._fw1.renderData.headers, { name = h, value = v } );
				return builder;
			},
			statusCode : function( v ) {
				if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
				request._fw1.renderData.statusCode = v;
				return builder;
			},
			statusText : function( v ) {
				if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
				request._fw1.renderData.statusText = v;
				return builder;
			},
			jsonpCallback : function( v ) {
				if ( !structKeyExists( request._fw1, 'renderData' ) ) request._fw1.renderData = { };
				request._fw1.renderData.jsonpCallback = v;
				return builder;
			}
		} );
		return builder;
	}

	public struct function renderDataWithContentType( struct renderData ) {
        var out = { };
        var renderType = renderData.type;
        var statusCode = renderData.statusCode;
        var statusText = renderData.statusText;

        var headers = structKeyExists( renderData, 'headers' ) ? renderData.headers : [];
        if ( isSimpleValue( renderType ) ) {
            var fn_type = 'render_' & renderType;
            if ( structKeyExists( variables, fn_type ) ) {
                renderType = variables[ fn_type ];
                // evaluate with no FW/1 context!
                out = renderType( request._fw1.renderData );
            } else {
                throw( type = 'FW1.UnsupportedRenderType',
                       message = 'Only HTML, JSON, JSONP, RAWJSON, XML, and TEXT are supported',
                       detail = 'renderData() called with unknown type: ' & renderType );
            }
        } else {
            // assume it is a function
            out = renderType( request._fw1.renderData );
        }

        var resp = getPageContext().getResponse();
        for ( var h in headers ) {
            resp.setHeader( h.name, h.value );
        }
        // in theory, we should use sendError() instead of setStatus() but some
        // Servlet containers interpret that to mean "Send my error page" instead
        // of just sending the response you actually want!
        if ( len( statusText ) ) {
            resp.setStatus( statusCode, statusText );
        } else {
            resp.setStatus( statusCode );
        }

        return out;
    }

     private struct function render_html( struct renderData ) {
        structDelete( request._fw1, 'renderData' );
        return {
            contentType = 'text/html; charset=utf-8',
            output = renderData.data
        };
    }

    private struct function render_json( struct renderData ) {
        return {
            contentType = 'application/json; charset=utf-8',
            output = serializeJSON( renderData.data )
        };
    }

     private struct function render_jsonp( struct renderData ) {
        if ( !structKeyExists( renderData, 'jsonpCallback' ) || !len( renderData.jsonpCallback ) ){
            throw( type = 'FW1.jsonpCallbackRequired',
                   message = 'Callback was not defined',
                   detail = 'renderData() called with jsonp type requires a jsonpCallback' );
        }
        return {
            contentType = 'application/javascript; charset=utf-8',
            output = renderData.jsonpCallback & "(" & serializeJSON( renderData.data ) & ");"
        };
    }

    private struct function render_rawjson( struct renderData ) {
        return {
            contentType = 'application/json; charset=utf-8',
            output = renderData.data
        };
    }

    private struct function render_text( struct renderData ) {
        return {
            contentType = 'text/plain; charset=utf-8',
            output = renderData.data
        };
    }

    private struct function render_xml( struct renderData ) {
        var output = '';
        if ( isXML( renderData.data ) ) {
            if ( isSimpleValue( renderData.data ) ) {
                // XML as string already
                output = renderData.data;
            } else {
                // XML object
                output = toString( renderData.data );
            }
        } else {
            throw( type = 'FW1.UnsupportXMLRender',
                   message = 'Data is not XML',
                   detail = 'renderData() called with XML type but unrecognized data format' );
        }
        return {
            contentType = 'text/xml; charset=utf-8',
            output = output
        };
    }
}