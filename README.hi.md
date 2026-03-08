[English](./README.md) | [简体中文](./README.zh-CN.md) | [Deutsch](./README.de.md) | [Français](./README.fr.md) | [Italiano](./README.it.md) | [日本語](./README.ja.md) | [한국어](./README.ko.md) | [हिन्दी](./README.hi.md) | [Bahasa Indonesia](./README.id.md) | [Tiếng Việt](./README.vi.md) | [ไทย](./README.th.md)

# FileUni Project

**FileUni** एक अगली पीढ़ी का स्टोरेज और फ़ाइल प्रबंधन प्लेटफ़ॉर्म है, जिसे प्रदर्शन, सुरक्षा और मॉड्यूलर डिप्लॉयमेंट के लिए Rust में बनाया गया है।

बहुत हल्के उपकरणों से लेकर पूर्ण सर्वरों तक, FileUni समर्पित हार्डवेयर के बिना NAS जैसी क्षमताएँ प्रदान करता है और CLI, GUI तथा web घटकों के लिए एक ही स्केलेबल कोडबेस बनाए रखता है।

## यह रिपॉजिटरी क्या है

यह रिपॉजिटरी FileUni का सार्वजनिक प्रोजेक्ट हब है। इसका मुख्य उपयोग है:

- स्वचालित build और release workflows
- सार्वजनिक issue tracking और feedback
- community-facing project coordination
- subtree-आधारित downstream sync targets

मुख्य development workspace निजी monorepo में है, और चुने हुए components को release तथा सार्वजनिक सहयोग के लिए यहाँ sync किया जाता है।

## FileUni क्यों

- Rust-आधारित उच्च-प्रदर्शन architecture
- अलग-अलग deployment आकारों के लिए modular design
- dedicated hardware के बिना NAS features
- FTP, SFTP, WebDAV और S3 सहित multi-protocol access
- storage workloads के लिए reliability और security पर फोकस

## संबंधित रिपॉजिटरी

- [FileUni Website](https://fileuni.com/)
- [FileUni Repositories](https://github.com/FileUni?tab=repositories)
- [OfficialSiteDocs](https://github.com/FileUni/OfficialSiteDocs)
- [OfficialSitePrivate](https://github.com/FileUni/OfficialSitePrivate)
- [yh-filemanager-vfs-storage-hub](https://github.com/FileUni/yh-filemanager-vfs-storage-hub)

## स्रोत उपलब्धता

इस रिपॉजिटरी में FileUni की सार्वजनिक project layer शामिल है। समय के साथ अतिरिक्त modules धीरे-धीरे खोले जा सकते हैं।

प्रकाशित source reading, review, release automation, और security या audit visibility के लिए है।

## उपयोग प्रतिबंध

- व्यावसायिक उपयोग की अनुमति नहीं है
- FileUni-आधारित प्रतिस्पर्धी उत्पाद बनाना या वितरित करना अनुमति प्राप्त नहीं है

उपयोग, licensing, या collaboration से जुड़े प्रश्नों के लिए कृपया इस रिपॉजिटरी में Issue खोलें।
