let selectedFile;

document.getElementById('pdf-upload').addEventListener('change', async function () {
    const file = this.files[0];
    if (file && file.type === "application/pdf") {
        selectedFile = file; // Store the file for S3 upload
        const fileReader = new FileReader();
        fileReader.onload = async function (e) {
            const arrayBuffer = e.target.result;

            // Load PDF into the iframe for viewing
            const pdfBlob = new Blob([arrayBuffer], { type: 'application/pdf' });
            document.getElementById('pdf-frame').src = URL.createObjectURL(pdfBlob);
            document.getElementById('pdf-frame').style.display = 'block';

            // Load PDF-lib to extract text
            const pdfDoc = await PDFLib.PDFDocument.load(arrayBuffer);
            let text = '';
            const pages = pdfDoc.getPages();
            for (const page of pages) {
                const textContent = await page.getTextContent();
                text += textContent.items.map(item => item.str).join(' ') + '\n\n';
            }

            // Display extracted text
            document.getElementById('text-output').value = text;
        };
        fileReader.readAsArrayBuffer(file);
    } else {
        alert("Please upload a valid PDF file.");
    }
});

async function uploadToS3() {
    

    try {
        // Start spinner
        const spinner = document.getElementById("spinner"); // Ensure there's a spinner element in your HTML
        spinner.style.display = "block"; // Show spinner

        if (!selectedFile) {
            alert("Please select a PDF file to upload first.")
            return
        }
    
    
        url = "https://wvccxln5fe.execute-api.us-east-1.amazonaws.com/prod/upload"
        const uploadResponse = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/pdf',
                'X-Filename': selectedFile.name
            },
            body: selectedFile // The PDF file to upload
        });

        if (uploadResponse.ok) {
            const responseData = await uploadResponse.json();  // Parse the JSON body

            // Display the extracted text in the textarea with ID 'text-output'
            document.getElementById("text-output").value = responseData.text;

            // Optionally hide the spinner
            document.getElementById("spinner").style.display = "none";

        } else {
            alert('Error uploading file.');
        }
    } catch (error) {
        console.error("Error uploading file:", error);
        alert("There was an error uploading your file.");
    }
}

function downloadExtractedText() {
    const textOutput = document.getElementById('text-output').value;
    const blob = new Blob([textOutput], { type: 'text/plain' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'extracted_text.txt';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
}
