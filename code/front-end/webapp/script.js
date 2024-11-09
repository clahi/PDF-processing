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
        const spinner = document.getElementById("spinner"); // Ensure there's a spinner element in your HTML
        spinner.style.display = "block"; // Show spinner

        if (!selectedFile) {
            alert("Please select a PDF file to upload first.")
            return
        }
    
    
        url = "https://d7fgygmn73.execute-api.us-east-1.amazonaws.com/prod/upload"
        const uploadResponse = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/pdf',
                'X-Filename': selectedFile.name
                // 'Content-Type': 'multipart/form-data'
            },
            body: selectedFile // The PDF file to upload
        });
        console.log("The response", uploadResponse)
        if (uploadResponse.ok) {
            const responseData = await uploadResponse.json();  // Parse the JSON body
            console.log("Full text extracted:", responseData.text);  // Access the 'text' field from the response

            // Display the extracted text in the textarea with ID 'text-output'
            document.getElementById("text-output").value = responseData.text;

            // Optionally hide the spinner
            document.getElementById("spinner").style.display = "none";

        } else {
            alert('Error uploading file.');
        }
        // alert(`File uploaded successfully: ${uploadResult.Location}`);

        // Start spinner for 1 minute
        // const spinner = document.getElementById("spinner"); // Ensure there's a spinner element in your HTML
        // spinner.style.display = "block"; // Show spinner
        setTimeout(() => {
            spinner.style.display = "none"; // Hide spinner after 1 minute
            // alert("Processing completed."); // Optional alert after spinner stops

            document.getElementById('download-button').click();
        }, 1000); // 60,000 ms = 1 minute
    } catch (error) {
        console.error("Error uploading file:", error);
        alert("There was an error uploading your file.");
    }
}

// async function downloadExtractedText() {
//     const fileKey = `processed/${selectedFile.name.replace('.pdf', '.txt')}`; // Replace with key structure for your text file

//     const params = {
//         Bucket: "my-bucket-serverless-source-01", // Replace with your bucket name
//         Key: fileKey
//     };

//     try {
//         const data = await s3.getObject(params).promise();
//         const text = data.Body.toString('utf-8');

//         // Display the downloaded text in the textarea
//         document.getElementById('text-output').value = text;
//         // alert("Text file downloaded successfully.");
//     } catch (error) {
//         console.error("Error downloading text file:", error);
//         alert("There was an error downloading your text file.");
//     }
// }






// async function uploadToS3() {
//     if (!selectedFile) {
//         alert("Please select a PDF file to upload first.");
//         return;
//     }

//     console.log("The selected file", selectedFile.name)
//     const params = {
//         Bucket: "my-bucket-serverless-source-01", // Replace with your bucket name
//         //   Key: `uploads/${selectedFile.name}`, // Adjust the key as desired

//         Key: `source/${selectedFile.name}`, // Adjust the key as desired
//         Body: selectedFile,
//         ContentType: "application/pdf"
//     };

//     try {
//         const spinner = document.getElementById("spinner"); // Ensure there's a spinner element in your HTML
//         spinner.style.display = "block"; // Show spinner
//         const uploadResult = await s3.upload(params).promise();
//         // alert(`File uploaded successfully: ${uploadResult.Location}`);

//         // Start spinner for 1 minute
//         // const spinner = document.getElementById("spinner"); // Ensure there's a spinner element in your HTML
//         // spinner.style.display = "block"; // Show spinner
//         setTimeout(() => {
//             spinner.style.display = "none"; // Hide spinner after 1 minute
//             // alert("Processing completed."); // Optional alert after spinner stops

//             document.getElementById('download-button').click();
//         }, 1000); // 60,000 ms = 1 minute
//     } catch (error) {
//         console.error("Error uploading file:", error);
//         alert("There was an error uploading your file.");
//     }
// }
// async function downloadExtractedText() {
//     const fileKey = `processed/${selectedFile.name.replace('.pdf', '.txt')}`; // Replace with key structure for your text file

//     const params = {
//         Bucket: "my-bucket-serverless-source-01", // Replace with your bucket name
//         Key: fileKey
//     };

//     try {
//         const data = await s3.getObject(params).promise();
//         const text = data.Body.toString('utf-8');

//         // Display the downloaded text in the textarea
//         document.getElementById('text-output').value = text;
//         // alert("Text file downloaded successfully.");
//     } catch (error) {
//         console.error("Error downloading text file:", error);
//         alert("There was an error downloading your text file.");
//     }
// }